# SPDX-FileCopyrightText: PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import hashlib
import os
import shutil
import subprocess
from pathlib import Path


STATUS_CONFIG = config.get("validation", {})
STATUS_ENABLED = STATUS_CONFIG.get("enable", True)

STATUS_REPOSITORY = STATUS_CONFIG.get(
    "status_repository",
    "submodules/pypsa-earth-status",
)

STATUS_REFERENCE_YEAR = int(STATUS_CONFIG.get("reference_year", 2023))


if STATUS_ENABLED:
    STATUS_ENVIRONMENT_FILE = Path(STATUS_REPOSITORY) / "envs/environment.yaml"

    if not STATUS_ENVIRONMENT_FILE.exists():
        raise FileNotFoundError(
            "PyPSA-Earth-Status environment file not found. "
            "Make sure the Git submodule is initialized."
        )

    STATUS_ENVIRONMENT_HASH = hashlib.sha256(
        STATUS_ENVIRONMENT_FILE.read_bytes()
    ).hexdigest()[:12]

    STATUS_ENVIRONMENT_PREFIX = f".snakemake/status/conda/{STATUS_ENVIRONMENT_HASH}"
    STATUS_ENVIRONMENT_MARKER = f".snakemake/status/env-{STATUS_ENVIRONMENT_HASH}.ready"


def _electricity_scenario_key(wildcards):
    return (
        f"elec_s{wildcards.simpl}_"
        f"{wildcards.clusters}_"
        f"ec_l{wildcards.ll}_"
        f"{wildcards.opts}"
    )


def electricity_status_outputs():
    if not STATUS_ENABLED:
        return []

    return expand(
        "results/"
        + RDIR
        + "validation/status/electricity/"
        + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.csv",
        simpl=config["scenario"]["simpl"],
        clusters=config["scenario"]["clusters"],
        ll=config["scenario"]["ll"],
        opts=config["scenario"]["opts"],
    )


if STATUS_ENABLED:

    rule prepare_status_environment:
        input:
            environment=str(STATUS_ENVIRONMENT_FILE),
        output:
            touch(STATUS_ENVIRONMENT_MARKER),
        run:
            environment_prefix = Path(STATUS_ENVIRONMENT_PREFIX).resolve()

            if environment_prefix.exists():
                shutil.rmtree(environment_prefix)

            environment_prefix.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            conda_executable = os.environ.get("CONDA_EXE") or shutil.which("conda")
            if conda_executable is None:
                raise FileNotFoundError(
                    "Could not find the Conda executable. "
                    "Neither CONDA_EXE nor a conda executable in PATH is available."
                )

            subprocess.run(
                [
                    conda_executable,
                    "env",
                    "create",
                    "--prefix",
                    str(environment_prefix),
                    "--file",
                    input.environment,
                ],
                check=True,
            )

    rule validate_network:
        input:
            network=(
                "results/"
                + RDIR
                + "networks/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.nc"
            ),
            status_environment=STATUS_ENVIRONMENT_MARKER,
        output:
            health_status=(
                "results/"
                + RDIR
                + "validation/status/electricity/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.csv"
            ),
        params:
            status_repository=STATUS_REPOSITORY,
            status_environment_prefix=STATUS_ENVIRONMENT_PREFIX,
            countries=config["countries"],
            year=STATUS_REFERENCE_YEAR,
            scenario_key=_electricity_scenario_key,
        log:
            (
                "logs/"
                + RDIR
                + "validation/status/electricity/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.log"
            ),
        script:
            "run_status_validation.py"
