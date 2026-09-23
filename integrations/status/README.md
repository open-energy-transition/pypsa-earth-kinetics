# PyPSA-Earth-Status integration

This directory contains the integration layer between PyPSA-Earth-KINETICS
and PyPSA-Earth-Status.

PyPSA-Earth-Status is included as a Git submodule under:

    submodules/pypsa-earth-status

The submodule points to the PyPSA-Earth-KINETICS integration fork:

    https://github.com/open-energy-transition/pypsa-earth-status-kinetics

This fork can temporarily host changes required by PyPSA-Earth-KINETICS before
they are proposed to the upstream PyPSA-Earth-Status repository.

The PyPSA-Earth-KINETICS models' configuration is authoritative for validation:

- countries are taken from `config["countries"]`;
- the historical reference year is defined by `validation.reference_year`;
- solved PyPSA-Earth-KINETICS networks are passed to PyPSA-Earth-Status automatically.

PyPSA-Earth-KINETICS-specific integration logic belongs in this directory.

Changes that improve PyPSA-Earth-Status independently of PyPSA-Earth-KINETICS should be
developed in the Status submodule and proposed upstream to:

    https://github.com/pypsa-meets-earth/pypsa-earth-status
