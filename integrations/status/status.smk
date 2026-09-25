# SPDX-FileCopyrightText: PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import hashlib
import os
import re
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

STATUS_PLANNING_HORIZONS = config.get("scenario", {}).get(
    "planning_horizons",
    [],
)
if not isinstance(STATUS_PLANNING_HORIZONS, (list, tuple)):
    STATUS_PLANNING_HORIZONS = [STATUS_PLANNING_HORIZONS]


_STATUS_RUN_NAMES = {}


def _status_validation_label(model_year):
    model_year = int(model_year)

    if model_year == STATUS_REFERENCE_YEAR:
        return f"historical_{STATUS_REFERENCE_YEAR}"

    return f"{model_year}_vs_{STATUS_REFERENCE_YEAR}"


def _status_run_name(validation_label):
    if validation_label in _STATUS_RUN_NAMES:
        return _STATUS_RUN_NAMES[validation_label]

    validation_root = Path(STATUS_REPOSITORY) / "results" / validation_label

    existing_runs = []

    if validation_root.exists():
        for path in validation_root.iterdir():
            match = re.fullmatch(r"run_(\d+)", path.name)

            if path.is_dir() and match:
                existing_runs.append(int(match.group(1)))

    run_name = f"run_{max(existing_runs, default=0) + 1:03d}"
    _STATUS_RUN_NAMES[validation_label] = run_name

    return run_name


def _electricity_model_year():
    snapshots = config.get("snapshots", {})

    if isinstance(snapshots, dict):
        start = snapshots.get("start")
    else:
        start = snapshots

    if start is not None:
        match = re.match(r"(\d{4})", str(start))

        if match:
            return int(match.group(1))

    if len(STATUS_PLANNING_HORIZONS) == 1:
        return int(STATUS_PLANNING_HORIZONS[0])

    return STATUS_REFERENCE_YEAR


if STATUS_ENABLED:
    STATUS_ELECTRICITY_MODEL_YEAR = _electricity_model_year()
    STATUS_ELECTRICITY_LABEL = _status_validation_label(STATUS_ELECTRICITY_MODEL_YEAR)
    STATUS_ELECTRICITY_RUN_NAME = _status_run_name(STATUS_ELECTRICITY_LABEL)


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


def _sector_scenario_key(wildcards):
    return (
        f"elec_s{wildcards.simpl}_"
        f"{wildcards.clusters}_"
        f"ec_l{wildcards.ll}_"
        f"{wildcards.opts}_"
        f"{wildcards.sopts}_"
        f"{wildcards.planning_horizons}_"
        f"{wildcards.discountrate}"
    )


def electricity_status_outputs():
    if not STATUS_ENABLED:
        return []

    return expand(
        STATUS_REPOSITORY
        + "/results/{validation_label}/{run_name}/"
        + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}/"
        + "figures/grid_network.png",
        validation_label=[STATUS_ELECTRICITY_LABEL],
        run_name=[STATUS_ELECTRICITY_RUN_NAME],
        simpl=config["scenario"]["simpl"],
        clusters=config["scenario"]["clusters"],
        ll=config["scenario"]["ll"],
        opts=config["scenario"]["opts"],
    )


def sector_status_outputs():
    if not STATUS_ENABLED:
        return []

    outputs = []

    for planning_horizon in STATUS_PLANNING_HORIZONS:
        validation_label = _status_validation_label(planning_horizon)
        run_name = _status_run_name(validation_label)

        scenario = dict(config["scenario"])
        scenario["planning_horizons"] = [planning_horizon]

        outputs.extend(
            expand(
                STATUS_REPOSITORY
                + "/results/{validation_label}/{run_name}/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_"
                + "{sopts}_{planning_horizons}_{discountrate}/"
                + "figures/grid_network.png",
                validation_label=[validation_label],
                run_name=[run_name],
                **scenario,
                **config["costs"],
            )
        )

    return outputs


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
            validation_result=(
                STATUS_REPOSITORY
                + "/results/{validation_label}/{run_name}/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}/"
                + "figures/grid_network.png"
            ),
        params:
            status_repository=STATUS_REPOSITORY,
            status_environment_prefix=STATUS_ENVIRONMENT_PREFIX,
            countries=config["countries"],
            year=STATUS_REFERENCE_YEAR,
            validation_name=lambda wildcards: (
                f"{wildcards.validation_label}/"
                f"{wildcards.run_name}/"
                f"{_electricity_scenario_key(wildcards)}"
            ),
            scenario_key=_electricity_scenario_key,
            osm_grid_path="resources/" + RDIR + "osm/clean",
        log:
            (
                "logs/"
                + RDIR
                + "validation/{validation_label}/{run_name}/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.log"
            ),
        script:
            "run_status_validation.py"


if STATUS_ENABLED:

    rule validate_sector_network:
        input:
            network=(
                RESDIR
                + "postnetworks/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_"
                + "{sopts}_{planning_horizons}_{discountrate}.nc"
            ),
            status_environment=STATUS_ENVIRONMENT_MARKER,
        output:
            validation_result=(
                STATUS_REPOSITORY
                + "/results/{validation_label}/{run_name}/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_"
                + "{sopts}_{planning_horizons}_{discountrate}/"
                + "figures/grid_network.png"
            ),
        params:
            status_repository=STATUS_REPOSITORY,
            status_environment_prefix=STATUS_ENVIRONMENT_PREFIX,
            countries=config["countries"],
            year=STATUS_REFERENCE_YEAR,
            validation_name=lambda wildcards: (
                f"{wildcards.validation_label}/"
                f"{wildcards.run_name}/"
                f"{_sector_scenario_key(wildcards)}"
            ),
            scenario_key=_sector_scenario_key,
            osm_grid_path="resources/" + RDIR + "osm/clean",
        log:
            (
                "logs/"
                + SECDIR
                + "validation/{validation_label}/{run_name}/"
                + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_"
                + "{sopts}_{planning_horizons}_{discountrate}.log"
            ),
        script:
            "run_status_validation.py"
