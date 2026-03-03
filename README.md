# Hamilton-Perry Population Projection

This repository contains an R script implementation for extending population projections using the **Hamilton-Perry Method**, specifically applied to the case study of Kota Semarang (2035–2050).

## Overview

Standard demographic forecasting relies on the Cohort-Component Method (CCM), which requires highly granular vital rates (births, deaths, migration). When such granular local data is missing but historical age-sex structure data is available, the macroscopic Hamilton-Perry Method is utilized.

This script extends the official Statistics Indonesia (BPS) deterministic projections from 2035 out to 2050 via 5-year recursive steps. To properly capture uncertainty, it generates three bounding scenarios (Minimum, Mean, and Maximum) by analyzing historical survivorship and fertility proxies (Cohort Change Ratios and Child-Woman Ratios) observed between 2020 and 2035.

## Data Requirements
- `kota_semarang_bps_data.csv`: Historical population structures (used for establishing baseline ratios).
- `Indonesia_UN_estimates.csv`: Macroeconomic demographic targets derived from United Nations World Population Prospects, utilized for external benchmarking.

## Methodology

For a complete and rigorous explanation of the algebraic and demographic assumptions embedded in this model, please review the [`technical.md`](technical.md) file included in this repository.

## How to Run

1. Ensure you have R installed along with the required packages: `dplyr`, `tidyr` (`tidyverse`), `stringr`, and `patchwork`.
2. Place the required input CSV files in the project root directory.
3. Source or execute `Hamilton-Perry.R` to run the model, which will:
   - Output summary tables of total and working-age populations to the console.
   - Generate comparative visualization plots (population pyramids and progression trajectories) using `ggplot2`.
