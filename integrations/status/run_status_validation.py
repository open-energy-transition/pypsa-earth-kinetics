# SPDX-FileCopyrightText: PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later

"""
Run PyPSA-Earth-Status validation for a solved PyPSA-Earth-KINETICS network.

The PyPSA-Earth-KINETICS configuration is authoritative for the validation context:
countries are inherited from PyPSA-Earth-KINETICS and the historical reference
year is defined by the PyPSA-Earth-KINETICS validation configuration.

PyPSA-Earth-Status is executed from a temporary copy of the pinned submodule
so that validation outputs do not modify the submodule working tree.
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

    with log_path.open("a") as stream:
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
output_path = Path(snakemake.output.health_status).resolve()
log_path = Path(snakemake.log[0]).resolve()

year = int(snakemake.params.year)
validation_name = str(snakemake.params.validation_name)
countries = list(snakemake.params.countries)
scenario_key = str(snakemake.params.scenario_key)
status_environment_prefix = Path(snakemake.params.status_environment_prefix).resolve()

if not status_repository.exists():
    raise FileNotFoundError(
        f"PyPSA-Earth-Status repository not found: {status_repository}"
    )

if not network_path.exists():
    raise FileNotFoundError(
        f"Solved PyPSA-Earth-KINETICS network not found: {network_path}"
    )

output_path.parent.mkdir(parents=True, exist_ok=True)

conda_executable = os.environ.get("CONDA_EXE") or shutil.which("conda")
if conda_executable is None:
    raise FileNotFoundError(
        "Could not find the Conda executable. "
        "Neither CONDA_EXE nor a conda executable in PATH is available."
    )

with tempfile.TemporaryDirectory(prefix="pypsa-earth-status-") as temporary_directory:
    status_workdir = Path(temporary_directory) / "pypsa-earth-status"

    # Use a temporary copy so the Status submodule remains untouched.
    # Local changes in the submodule are copied as well, which allows
    # upstream Status changes to be tested from PyPSA-Earth-KINETICS before opening a PR.
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
    validation_config["networks"] = {
        scenario_key: {
            "path": str(network_path),
            "countries": countries,
        }
    }

    with status_config_path.open("w") as stream:
        yaml.safe_dump(
            status_config,
            stream,
            sort_keys=False,
        )

    # Status currently keeps an incremental repository-level result.
    # Remove the copied result so this run contains only this network.
    status_output = status_workdir / "results" / "health_status.csv"
    status_backup = Path(str(status_output) + ".tmp")

    if status_output.exists():
        status_output.unlink()

    if status_backup.exists():
        status_backup.unlink()

    run_command(
        [
            conda_executable,
            "run",
            "--prefix",
            str(status_environment_prefix),
            "snakemake",
            "-j",
            "1",
            "build_health_status",
            "--rerun-incomplete",
        ],
        cwd=status_workdir,
        log_path=log_path,
    )

    if not status_output.exists():
        raise FileNotFoundError(
            "PyPSA-Earth-Status did not produce " f"{status_output}"
        )

    shutil.copy2(
        status_output,
        output_path,
    )
