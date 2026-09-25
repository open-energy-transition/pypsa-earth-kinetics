# SPDX-FileCopyrightText: PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later

"""
Run the standard PyPSA-Earth-Status validation workflow for a solved
PyPSA-Earth-KINETICS network.

PyPSA-Earth-Status is executed from a temporary copy of the pinned submodule.
The complete Status validation results directory is then copied back into the
PyPSA-Earth-KINETICS results directory.
"""

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import yaml


def run_command(command, cwd, log_path):
    """Run a command and redirect stdout and stderr to the rule log."""
    log_path.parent.mkdir(parents=True, exist_ok=True)

    with log_path.open("w") as stream:
        subprocess.run(
            command,
            cwd=cwd,
            stdout=stream,
            stderr=subprocess.STDOUT,
            check=True,
        )


repo_root = Path.cwd().resolve()

status_repository = (repo_root / snakemake.params.status_repository).resolve()
network_path = Path(snakemake.input.network).resolve()

validation_result = Path(snakemake.output.validation_result).resolve()
output_directory = validation_result.parents[1]

log_path = Path(snakemake.log[0]).resolve()

year = int(snakemake.params.year)
validation_name = str(snakemake.params.validation_name)
countries = list(snakemake.params.countries)

status_environment_prefix = Path(snakemake.params.status_environment_prefix).resolve()

osm_grid_path = (repo_root / snakemake.params.osm_grid_path).resolve()


if not status_repository.exists():
    raise FileNotFoundError(
        f"PyPSA-Earth-Status repository not found: {status_repository}"
    )

if not network_path.exists():
    raise FileNotFoundError(
        f"Solved PyPSA-Earth-KINETICS network not found: {network_path}"
    )

for osm_file in (
    osm_grid_path / "all_clean_lines.geojson",
    osm_grid_path / "all_clean_substations.geojson",
):
    if not osm_file.exists():
        raise FileNotFoundError(
            f"OSM grid file required by PyPSA-Earth-Status not found: {osm_file}"
        )


conda_executable = os.environ.get("CONDA_EXE") or shutil.which("conda")
if conda_executable is None:
    raise FileNotFoundError(
        "Could not find the Conda executable. "
        "Neither CONDA_EXE nor a conda executable in PATH is available."
    )


with tempfile.TemporaryDirectory(prefix="pypsa-earth-status-") as temporary_directory:
    status_workdir = Path(temporary_directory) / "pypsa-earth-status"

    shutil.copytree(
        status_repository,
        status_workdir,
        ignore=shutil.ignore_patterns(".git"),
    )

    status_config_path = status_workdir / "config.yaml"

    with status_config_path.open() as stream:
        status_config = yaml.safe_load(stream)

    validation_config = status_config["network_validation"]

    validation_config["name"] = validation_name
    validation_config["network_path"] = str(network_path)
    validation_config["countries"] = countries
    validation_config["year"] = [year]

    status_config["plot_osm_grid_network"]["grid_path"] = str(osm_grid_path)

    with status_config_path.open("w") as stream:
        yaml.safe_dump(
            status_config,
            stream,
            sort_keys=False,
        )

    status_results = status_workdir / "results" / validation_name

    if status_results.exists():
        shutil.rmtree(status_results)

    run_command(
        [
            conda_executable,
            "run",
            "--prefix",
            str(status_environment_prefix),
            "snakemake",
            "-j",
            "1",
            "visualize_data",
            "--rerun-incomplete",
        ],
        cwd=status_workdir,
        log_path=log_path,
    )

    if not status_results.exists():
        raise FileNotFoundError(
            "PyPSA-Earth-Status did not produce the expected results "
            f"directory: {status_results}"
        )

    if output_directory.exists():
        shutil.rmtree(output_directory)

    shutil.copytree(
        status_results,
        output_directory,
    )

    if not validation_result.exists():
        raise FileNotFoundError(
            "Expected PyPSA-Earth-Status validation output was not produced: "
            f"{validation_result}"
        )
