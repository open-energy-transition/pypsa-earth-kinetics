<!--
SPDX-FileCopyrightText: PyPSA-Earth and PyPSA-Eur Authors

SPDX-License-Identifier: CC-BY-4.0
-->

# Japan (JP) residential fuel shares

This note documents the JP row in `data/demand/fuel_shares.csv`
used by `scripts/prepare_energy_totals.py`.

## Motivation

Japan previously inherited the DEFAULT fuel shares, including
an exogenous substitution of 50% of residential oil consumption
with electricity.

This substitution was also applied to historical simulations,
preventing the model from reproducing observed final energy
consumption.

Japan-specific shares are introduced to preserve historical fuel
balances and improve the allocation of residential energy demand.

## Sources

| Source | Used for |
|---|---|
| [HPTCJ, Heat Pump & Thermal Storage System Data Book 2024, section 7](https://www.hptcj.or.jp/download/assets/pdf/DataBook_2024.pdf) | FY2023 residential space and water heating consumption by fuel, based on EDMC 2025 |
| [METI, energy education materials](https://energy-kyoiku.meti.go.jp/wp-content/themes/energy/assets/pdf/teaching-materials/downloads/type-orange/k2/chu_seito_link.pdf) | FY2023 total household energy consumption and fuel shares, based on EDMC |
| [UNSD Energy Statistics](https://data.un.org/) | National final energy consumption by fuel |
| [Japan demand growth rates](japan_growth_rates.md) | Fuel-specific demand projections |

## Reference data

FY2023 household final energy consumption, in thousands of kcal
per household per year:

| Fuel | Space heating | Water heating |
|---|---:|---:|
| Electricity | 635 | 231 |
| City gas | 244 | 964 |
| LPG | 73 | 453 |
| Kerosene | 882 | 283 |

Total household consumption is approximately 7,280 thousand
kcal per year, with the following fuel shares:

| Fuel | Share |
|---|---:|
| Electricity | 53.0% |
| City gas | 20.1% |
| LPG | 10.5% |
| Kerosene | 16.0% |
| Other | 0.4% |

LPG and kerosene are grouped under oil, consistently with
the UNSD fuel aggregation used by the model.

## Method

The fraction of each fuel allocated to heating is calculated
as space and water heating consumption divided by total
residential consumption of that fuel.

Oil heating share:

    (73 + 453 + 882 + 283) / (7280 * (0.105 + 0.160))
    = 0.8765

Gas heating share:

    (244 + 964) / (7280 * 0.201)
    = 0.8255

Space heating share of fossil-fuel thermal consumption:

    (244 + 73 + 882) / (244 + 73 + 882 + 964 + 453 + 283)
    = 0.4136

Electricity is excluded from this last calculation because
existing electric heating is handled separately in the model.

## Values

| Parameter | DEFAULT | JP | Basis |
|---|---:|---:|---|
| oil residential heat share | 0.6667 | 0.8765 | EDMC FY2023 |
| biomass residential heat share | 0.75 | 0.75 | Default retained |
| biomass to elec heat share | 0 | 0 | No additional fuel switching |
| oil to elec heat share | 0.5 | 0 | Preserve historical fuel consumption |
| biomass to elec share | 0 | 0 | No additional fuel switching |
| oil to elec share | 0.5 | 0 | Preserve historical fuel consumption |
| space to water heat share | 0.6 | 0.4136 | EDMC FY2023 fossil-fuel heating |
| gas to elec share | 0 | 0 | No additional fuel switching |
| gas to elec heat share | 0 | 0 | No additional fuel switching |
| gas residential heat share | 0.75 | 0.8255 | EDMC FY2023 |

Exogenous fuel switching is disabled for Japan to preserve
the historical fuel balance and avoid overlapping with the
fuel-specific demand projections.

## Model check

Residential final energy demand from `prepare_energy_totals`,
in TWh, with UNSD SDMX and base year 2023:

| Fuel | 2023 DEFAULT | 2023 JP | 2030 JP |
|---|---:|---:|---:|
| Electricity | 269.058 | 250.861 | 244.435 |
| Oil | 54.597 | 109.193 | 93.648 |
| Gas | 106.750 | 106.750 | 103.214 |
| Biomass | 0.047 | 0.047 | 0.044 |

Oil, gas and biomass totals include both heating and
non-heating consumption.

The Japan-specific heating shares change the end-use allocation
without changing the total consumption of each fuel.

## Limitations

- Source values are rounded and the derived shares are approximate.
- FY2023 shares are also applied to future planning horizons.
- Biomass is not reported separately in the end-use reference
  data, so its default heating share is retained.
- A common space-to-water heating ratio is applied to all fuels,
  although actual ratios differ substantially by fuel.
- The data represent final energy, not useful heat.
- Existing electric heating and its conversion to useful heat
  require further investigation.
- District heating shares have not yet been calibrated for Japan.
- Validation of the revised shares currently covers demand
  preprocessing, not a solved network.
