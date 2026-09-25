# SPDX-FileCopyrightText: PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later

"""
Run PyPSA-Earth-Status directly from its submodule for a solved
PyPSA-Earth-KINETICS network.

The KINETICS network, countries, reference year, validation name, and OSM grid
path are injected through a temporary Status configuration. The standard
PyPSA-Earth-Status ``visualize_data`` workflow then writes its normal outputs
directly to the submodule's results directory.
"""

import fcntl
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import yaml


def run_command(command, cwd, log_path):
    """Run a command and redirect stdout and stderr to the wrapper log."""
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


status_config_path = status_repository / "config.yaml"

with status_config_path.open() as stream:
    status_config = yaml.safe_load(stream)

validation_config = status_config["network_validation"]

validation_config["name"] = validation_name
validation_config["network_path"] = str(network_path)
validation_config["countries"] = countries
validation_config["year"] = [year]

status_config["plot_osm_grid_network"]["grid_path"] = str(osm_grid_path)


temporary_config = None

try:
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".yaml",
        prefix=".kinetics-validation-",
        dir=status_repository,
        delete=False,
    ) as stream:
        yaml.safe_dump(
            status_config,
            stream,
            sort_keys=False,
        )
        temporary_config = Path(stream.name)

    lock_path = repo_root / ".snakemake/status/validation.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)

    with lock_path.open("w") as lock_stream:
        fcntl.flock(lock_stream, fcntl.LOCK_EX)

        run_command(
            [
                conda_executable,
                "run",
                "--prefix",
                str(status_environment_prefix),
                "snakemake",
                "-j",
                "1",
                "--configfile",
                str(temporary_config),
                "--rerun-incomplete",
                "visualize_data",
            ],
            cwd=status_repository,
            log_path=log_path,
        )

finally:
    if temporary_config is not None:
        temporary_config.unlink(missing_ok=True)


if not validation_result.exists():
    raise FileNotFoundError(
        "PyPSA-Earth-Status did not produce the expected validation result: "
        f"{validation_result}"
    )
