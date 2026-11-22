<!--
SPDX-FileCopyrightText: 2026 Open Energy Transition gGmbH
SPDX-License-Identifier: CC-BY-4.0
-->

# CO2 sector policy

Country-, sector-, and subsector-specific CO2 limits can be configured through
the file referenced by:

```yaml
co2:
  sector_policy:
    policy_file: "configs/policy/co2_sector_limits.csv"
```

The policy is applied when a `Co2L` option is active.

The CSV format is:

```text
year,country,sector,subsector,limit_tco2_per_year
```

The fields have the following semantics:

- `year`: planning horizon to which the limit applies.
- `country`: uppercase country code, for example `US`.
- `sector`: emitting sector.
- `subsector`: optional emitting subsector. Leave blank for an aggregate sector limit.
- `limit_tco2_per_year`: annual CO2 limit in tonnes. Use `inf` to explicitly disable a limit.

A blank `subsector` applies to all subsectors within the selected sector.
A populated `subsector` applies only to that exact subsector. Aggregate sector
and subsector-specific limits may coexist.

Rows for other planning horizons are ignored. If no row exists for a
country/sector combination, no additional sector-specific CO2 constraint is
applied.

Supported sector classifications include:

- `power_and_heat_generation`: `power`, `heat`, `chp`
- `agriculture`
- `residential`
- `services`
- `industry`
- `industry_process_emissions`
- `transport`: `road_transport`, `non_road_rail`, `non_road_aviation`, `non_road_shipping`
- `hydrogen`: `grid_h2`, `green_h2`, `grey_h2`, `blue_h2`

The default `co2_sector_limits.csv` is intentionally header-only.
`co2_sector_limits.example.csv` provides an example policy.

For multi-country models, emitting components must be attributable to a
country. Ambiguous direct-emitting components are not assigned arbitrarily;
the solver raises an error if such a component is covered by an active policy.

## Japan policy datasets

| Country | CSV file | Source |
|---|---|---|
| Japan (JP) | `co2_sector_limits_jp_indc2015.csv` | [Japan's Intended Nationally Determined Contribution (INDC), 2015 — Ministry of the Environment](https://www.env.go.jp/en/earth/cc/2030indc.html) |
| Japan (JP) | `co2_sector_limits_jp_gw_plan2025_conservative.csv` | [Japan's Global Warming Countermeasures Plan, 2025 — Ministry of the Environment](https://www.env.go.jp/content/000338678.pdf) |
| Japan (JP) | `co2_sector_limits_jp_gw_plan2025_ambitious.csv` | [Japan's Global Warming Countermeasures Plan, 2025 — Ministry of the Environment](https://www.env.go.jp/content/000338678.pdf) |
| Japan (JP) | `co2_sector_limits_jp_iea_emissions.csv` | [Japan: Emissions — International Energy Agency (IEA)](https://www.iea.org/countries/japan/emissions) |

## Japan agriculture emissions accounting

The IEA 2023 agriculture reference is 7,263,900 tCO2/year,
whereas the Japan sector model produces approximately
12.63 MtCO2/year from UNSD-based agriculture, forestry and
fishing fuel consumption using the 2019 base year.

The discrepancy may reflect differences in reference years
and sectoral accounting boundaries, which have not yet been
reconciled.

The agriculture-specific constraint is therefore disabled
(`inf`) in the IEA 2023 policy CSV.

The original IEA value is preserved in the optional `notes`
column. This column is informational and ignored by the solver.

The other Japan policy datasets originally specified `inf`
for agriculture. Their notes retain this original value and
include the IEA 2023 figure for historical reference only,
not as a 2030 or 2040 target.

Agricultural fuel consumption and associated CO2 emissions
remain included in the model and national CO2 accounting.
