<!--
SPDX-FileCopyrightText:  PyPSA-Earth and PyPSA-Eur Authors

SPDX-License-Identifier: CC-BY-4.0
-->

# Japan (JP) demand growth rates

This note documents the `JP` rows in the demand growth files used by
sector-coupled runs.

| File | JP row |
|---|---|
| `data/demand/growth_factors_cagr.csv` | Growth of energy demand in buildings, transport and agriculture |
| `data/demand/industry_growth_cagr.csv` | Growth of industrial production by sector |
| `data/demand/efficiency_gains_cagr.csv` | All zeros (see Method) |

Without these rows Japan used the `DEFAULT` row (Moroccan rates of 2–5% a
year), which overstates 2030 electricity demand by about half.

## How the model uses them

Each value is a yearly growth rate, compounded from the demand base year
(2019) to the planning horizon:

 `factor = (1 + rate) ^ (horizon - 2019)`.

## Sources

| Source | Used for |
|---|---|
| [APERC, APEC Energy Demand and Supply Outlook, 9th ed. (2025)](https://aperc.or.jp/reports/outlook.php), reference scenario | Energy demand by sector, fuel and transport mode; most industry sectors |
| [METI, Outlook for Energy Supply and Demand in FY2040 (2025)](https://www.enecho.meti.go.jp/en/category/others/basic_plan/pdf/outlook_for_energy_supply_and_demand_in_fy2040.pdf) | Steel, cement and chemicals production; commercial energy; cross-check |
| [EIA, International Energy Outlook 2023](https://www.eia.gov/outlooks/ieo/) | Cross-check only |

## Method

- `rate = (value_2030 / value_2019) ^ (1/11) - 1`, rounded to four decimals.
- APERC is the main source: it is the only one with Japan data by fuel and
  transport mode, and it includes actual 2019 data.
- METI is used for steel, cement and chemicals because it states production.
  Its energy figures are not used as inputs because they assume Japan's 73%
  emissions cut and would build policy outcomes into demand.
- The source figures already include efficiency gains, so the `JP` efficiency
  row is zero to avoid counting them twice.

## Values

### `growth_factors_cagr.csv`

| Column | JP | Basis |
|---|---|---|
| total residential space / water | -0.0086 | APERC residential, all fuels |
| electricity residential | -0.0037 | APERC residential electricity |
| total services space / water | -0.0060 | METI commercial energy (midpoint) |
| services electricity | 0 | Sources disagree; 0 lies between them |
| total road | -0.0089 | APERC |
| total rail / electricity rail | -0.0039 / -0.0036 | APERC |
| total domestic aviation | -0.0109 | APERC |
| total international aviation | +0.0132 | APERC bunkers |
| total domestic navigation | 0 | APERC (+0.0004, set to 0) |
| total international navigation | +0.0152 | APERC bunkers |
| agriculture electricity / oil | +0.0021 / -0.0082 | APERC |
| residential oil, residential heat oil | -0.0217 | APERC |
| residential gas, residential heat gas | -0.0048 | APERC |
| services oil / gas | -0.0262 / -0.0167 | APERC |
| residential biomass, residential heat biomass | -0.0071 | No Japan data; US value kept |
| agriculture biomass, services biomass, other * | 0 | No usable data |

### `industry_growth_cagr.csv`

| Column | JP | Basis |
|---|---|---|
| chemical and petrochemical | +0.0025 | METI ethylene and propylene production |
| iron and steel | +0.0015 | METI crude steel production |
| non-metallic minerals | -0.0002 | METI cement production |
| construction | +0.0011 | APERC, 2019–2040 (2019–2030 distorted by a one-off jump) |
| food and tobacco | +0.0040 | APERC |
| machinery | -0.0010 | APERC |
| mining and quarrying | -0.0052 | APERC |
| non-ferrous metals | -0.0010 | APERC |
| paper pulp and print | -0.0103 | APERC |
| textile and leather | -0.0136 | APERC |
| transport equipment | -0.0076 | APERC |
| wood and wood products | -0.0017 | APERC |
| ammonia | +0.0025 | Assumption: follows chemicals |
| other | -0.0130 | APERC non-specified industry |

## Check in a model run

A sector-coupled 2030 run for Japan (60 clusters, weather year 2023) was
solved with three sets of growth rates. Annual electricity demand, in TWh:

| Load | DEFAULT | US | **JP** |
|---|---|---|---|
| Residential and other AC | 439.2 | 278.3 | **243.3** |
| Industry | 450.9 | 377.9 | **331.5** |
| Services | 460.7 | 335.6 | **317.7** |
| Rail | 26.0 | 17.3 | **16.6** |
| Agriculture | 4.5 | 3.7 | **3.8** |
| **Total** | **1,381** | **1,013** | **913** |

With the `JP` rows, demand is close to METI's actual 900 TWh for FY2022 and
within its 900–1,100 TWh range for FY2040.

## Limitations

- Rates are fitted to 2019–2030 and reused for later horizons.
- Space and water heat follow total sector energy, as no source splits heat
  by end use.
- METI production rates start from FY2023, not 2019.
