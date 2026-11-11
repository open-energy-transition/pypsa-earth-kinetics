<!--
SPDX-FileCopyrightText: 2026 Open Energy Transition gGmbH
SPDX-License-Identifier: CC-BY-4.0
-->

# CO2 policy data sources

This file lists the sources used for the country-specific CO2 policy CSV files in this directory.

`co2_sector_limits.csv` is the default policy file referenced by the main
configuration and is intentionally header-only, so sector-specific CO2 limits
are disabled unless explicitly configured. `co2_sector_limits.example.csv`
provides an example of the supported sector and subsector structure.


| Country | CSV file | Source |
|---|---|---|
| Japan (JP) | `co2_sector_limits_jp_indc2015.csv` | [Japan's Intended Nationally Determined Contribution (INDC), 2015 — Ministry of the Environment](https://www.env.go.jp/en/earth/cc/2030indc.html) |
| Japan (JP) | `co2_sector_limits_jp_gw_plan2025_conservative.csv` | [Japan's Global Warming Countermeasures Plan, 2025 — Ministry of the Environment](https://www.env.go.jp/content/000338678.pdf) |
| Japan (JP) | `co2_sector_limits_jp_gw_plan2025_ambitious.csv` | [Japan's Global Warming Countermeasures Plan, 2025 — Ministry of the Environment](https://www.env.go.jp/content/000338678.pdf) |
| Japan (JP) | `co2_sector_limits_jp_iea_emissions.csv` | [Japan: Emissions — International Energy Agency (IEA)](https://www.iea.org/countries/japan/emissions) |
