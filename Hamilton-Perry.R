# ==============================================================================
# Extending Population Projections for Kota Semarang (2035 - 2050)
# Methodology: Hamilton-Perry Method with Scenario Bounds (Min/Mean/Max)
# nolint start: object_usage_linter, indentation_linter
# ==============================================================================

# Install required packages if you don't have them
# install.packages(c("tidyverse", "stringr", "patchwork"))

library(tidyverse)
library(stringr)
library(patchwork)

# ==============================================================================
# Brand Color Palette Setup
# ==============================================================================
brand_colors <- c(
  dark_teal = "#294648",
  lime_olive = "#9cbd1b",
  green_yellow = "#88b027",
  dark_green = "#00883c",
  mid_green = "#439f36",
  yellow_green = "#bbc808",
  forest_green = "#0d933a",
  bright_yel = "#c7d301"
)

# Map specific brand colors to data categories
# 1. Sex Palette (Used in the Pyramid Plot)
color_sex <- c(
  "male"   = as.character(brand_colors["dark_teal"]),
  "female" = as.character(brand_colors["lime_olive"])
)

# 2. Scenario Palette (Used in the Trajectory Plots)
# Ground the historical data in the darkest color, and use a gradient of
# greens/yellows for the projections.
color_scenarios <- c(
  "Historical (BPS)" = as.character(brand_colors["dark_teal"]),
  "Max"              = as.character(brand_colors["dark_green"]),
  "Mean"             = as.character(brand_colors["mid_green"]),
  "Min"              = as.character(brand_colors["bright_yel"]),
  # Map UN variants to match the equivalent Hamilton-Perry scenarios
  "High"             = as.character(brand_colors["dark_green"]),
  "Momentum"         = as.character(brand_colors["mid_green"]),
  "Low"              = as.character(brand_colors["bright_yel"])
)

# Suppress CMD check/lintr warnings for variables used in dplyr pipelines
utils::globalVariables(c(
  "year", "sex", "age_group", "age_start",
  "pop", "pop_t5", "pop_t", "prev_age_pop_t",
  "ccr", "total", "cwr", "period",
  "PopTotal", "Variant", "Time", "AgeGrpStart",
  "projected_pop", "total_population", "working_age_pop",
  "pop_plot", "year_factor", "scenario"
))

# ------------------------------------------------------------------------------
# 1. Data Loading and Preparation
# ------------------------------------------------------------------------------
# Ensure the file name matches your working directory exactly
file_path <- "data/kota_semarang_bps_data.csv"
df <- read_csv(file_path)

# Pivot the data to a long format and filter for 5-year intervals
df_long <- df |>
  pivot_longer(cols = `2020`:`2035`, names_to = "year", values_to = "pop") |>
  mutate(year = as.numeric(year)) |>
  filter(year %in% c(2020, 2025, 2030, 2035))

# Extract the numeric start of the age group to ensure proper mathematical sorting
# (e.g., "5-9" becomes 5, "75+" becomes 75)
df_long <- df_long |>
  mutate(age_start = as.numeric(str_extract(age_group, "^[0-9]+"))) |>
  arrange(year, sex, age_start)

# Identify the maximum age group (the open-ended group, likely 75+)
max_age_start <- max(df_long$age_start)
age_groups <- unique(df_long$age_group[order(df_long$age_start)])

# ------------------------------------------------------------------------------
# 2. Calculate Historical Ratios (2020-2025, 2025-2030, 2030-2035)
# ------------------------------------------------------------------------------

# Function to calculate ratios for a specific transition (e.g., 2020 to 2025)
calculate_transition_ratios <- function(data, year_t, year_t5) {
  pop_t <- data |> filter(year == year_t)
  pop_t5 <- data |> filter(year == year_t5)

  ratios <- pop_t5 |>
    select(sex, age_group, age_start, pop_t5 = pop) |>
    left_join(pop_t |> select(sex, age_group, age_start, pop_t = pop),
      by = c("sex", "age_group", "age_start")
    )

  # Calculate Cohort Change Ratios (CCR)
  # CCR = Pop(age x+5, t+5) / Pop(age x, t)
  ccr_data <- ratios |>
    group_by(sex) |>
    mutate(
      prev_age_pop_t = lag(pop_t, n = 1),
      ccr = ifelse(age_start == 0, NA, pop_t5 / prev_age_pop_t)
    ) |>
    ungroup()

  # Handle the open-ended age group separately (e.g., 75+)
  # CCR_open = Pop(75+, t+5) / (Pop(70-74, t) + Pop(75+, t))
  for (s in unique(ccr_data$sex)) {
    pop_open_t5 <- ccr_data$pop_t5[ccr_data$sex == s & ccr_data$age_start == max_age_start]
    pop_open_t <- ccr_data$pop_t[ccr_data$sex == s & ccr_data$age_start == max_age_start]
    pop_prior_t <- ccr_data$pop_t[ccr_data$sex == s & ccr_data$age_start == (max_age_start - 5)]

    ccr_open <- pop_open_t5 / (pop_open_t + pop_prior_t)
    ccr_data$ccr[ccr_data$sex == s & ccr_data$age_start == max_age_start] <- ccr_open
  }

  # Calculate Child-Woman Ratios (CWR) for ages 0-4
  # CWR = Pop(0-4, t+5) / Sum(Females 15-49, t+5)
  # Standard Hamilton-Perry relates children in year t+5 to women in year t+5
  females_15_49_t5 <- data |>
    filter(year == year_t5, sex == "female", age_start >= 15, age_start <= 49) |>
    summarise(total = sum(pop)) |>
    pull(total)

  # Assign the calculated CWR directly to the 0-4 age group
  ccr_data <- ccr_data |>
    mutate(
      cwr = ifelse(age_start == 0, pop_t5 / females_15_49_t5, NA),
      period = paste0(year_t, "-", year_t5)
    )

  return(ccr_data |> select(sex, age_group, age_start, period, ccr, cwr))
}

# Apply the function to all historical transition periods in our data
ratios_20_25 <- calculate_transition_ratios(df_long, 2020, 2025)
ratios_25_30 <- calculate_transition_ratios(df_long, 2025, 2030)
ratios_30_35 <- calculate_transition_ratios(df_long, 2030, 2035)

all_ratios <- bind_rows(ratios_20_25, ratios_25_30, ratios_30_35)

# ------------------------------------------------------------------------------
# 3. Create Projection Parameters (Min, Mean, Max Scenarios)
# ------------------------------------------------------------------------------
projection_parameters <- all_ratios |>
  group_by(sex, age_group, age_start) |>
  summarise(
    ccr_min = if (all(is.na(ccr))) NA_real_ else min(ccr, na.rm = TRUE),
    ccr_mean = if (all(is.na(ccr))) NA_real_ else mean(ccr, na.rm = TRUE),
    ccr_max = if (all(is.na(ccr))) NA_real_ else max(ccr, na.rm = TRUE),
    cwr_min = if (all(is.na(cwr))) NA_real_ else min(cwr, na.rm = TRUE),
    cwr_mean = if (all(is.na(cwr))) NA_real_ else mean(cwr, na.rm = TRUE),
    cwr_max = if (all(is.na(cwr))) NA_real_ else max(cwr, na.rm = TRUE),
    .groups = "drop"
  )

# ------------------------------------------------------------------------------
# 4. Core Projection Engine (Recursive 5-Year Steps)
# ------------------------------------------------------------------------------
project_5_years <- function(base_pop, params, scenario = "mean") {
  # Determine which columns to use based on the selected scenario
  ccr_col <- paste0("ccr_", scenario)
  cwr_col <- paste0("cwr_", scenario)

  next_pop <- base_pop |>
    left_join(params |> select(sex, age_group, age_start, !!sym(ccr_col), !!sym(cwr_col)),
      by = c("sex", "age_group", "age_start")
    )

  result <- next_pop |> mutate(projected_pop = 0)

  # Step A: Project ages 5 and older using CCRs
  for (s in unique(result$sex)) {
    # 1. Standard cohorts
    for (a in seq(5, max_age_start - 5, by = 5)) {
      base_val <- base_pop$pop[base_pop$sex == s &
        base_pop$age_start == (a - 5)]
      ccr_val <- params[[ccr_col]][params$sex == s & params$age_start == a]
      result$projected_pop[result$sex == s & result$age_start == a] <-
        base_val * ccr_val
    }

    # 2. Open-ended cohort (e.g., 75+)
    base_val_open <- base_pop$pop[base_pop$sex == s &
      base_pop$age_start == max_age_start]
    base_val_prior <- base_pop$pop[base_pop$sex == s &
      base_pop$age_start == (max_age_start - 5)]
    ccr_val_open <- params[[ccr_col]][params$sex == s &
      params$age_start == max_age_start]

    result$projected_pop[result$sex == s &
      result$age_start == max_age_start] <-
      (base_val_open + base_val_prior) * ccr_val_open
  }

  # Step B: Project ages 0-4 using CWR and the newly projected women 15-49
  projected_females_15_49 <- sum(
    result$projected_pop[result$sex == "female" &
      result$age_start >= 15 &
      result$age_start <= 49]
  )

  for (s in unique(result$sex)) {
    cwr_val <- params[[cwr_col]][params$sex == s & params$age_start == 0]
    result$projected_pop[result$sex == s & result$age_start == 0] <-
      projected_females_15_49 * cwr_val
  }

  # Clean up dataframe for the next iteration
  final_result <- result |>
    select(sex, age_group, age_start, pop = projected_pop)

  final_result
}

# ------------------------------------------------------------------------------
# 5. Execute Projections to 2050
# ------------------------------------------------------------------------------
# Set the 2035 population as our final known base
pop_2035 <- df_long |>
  filter(year == 2035) |>
  select(sex, age_group, age_start, pop)

scenarios <- c("min", "mean", "max")
final_projections <- list()

# Run the recursive projection loop for each scenario
for (scn in scenarios) {
  pop_2040 <- project_5_years(
    pop_2035, projection_parameters,
    scenario = scn
  ) |>
    mutate(year = 2040, scenario = scn)
  pop_2045 <- project_5_years(
    pop_2040, projection_parameters,
    scenario = scn
  ) |>
    mutate(year = 2045, scenario = scn)
  pop_2050 <- project_5_years(
    pop_2045, projection_parameters,
    scenario = scn
  ) |>
    mutate(year = 2050, scenario = scn)

  # Combine all projected years for this scenario to allow continuous plotting
  final_projections[[scn]] <- bind_rows(pop_2040, pop_2045, pop_2050)
}

# Combine all projections into a single comprehensive dataframe
projected_data <- bind_rows(final_projections)
results_2050 <- projected_data |> filter(year == 2050)

# ------------------------------------------------------------------------------
# 6. View Summary Ranges and Export
# ------------------------------------------------------------------------------
# Calculate Total Population Range for 2050 across scenarios
summary_2050 <- results_2050 |>
  group_by(scenario) |>
  summarise(total_population = sum(pop)) |>
  arrange(total_population)

cat("\n=======================================================\n")
cat("Projected Total Population Range for Kota Semarang in 2050:\n")
cat("=======================================================\n")
print(summary_2050)

# ------------------------------------------------------------------------------
# 7. Working-Age Population (15-64) Estimate for 2050
# ------------------------------------------------------------------------------
# The internationally recognized working-age demographic is 15-64.
# In our 5-year bracket data, this corresponds to age_start >= 15 and <= 60.
working_age_2050 <- results_2050 |>
  filter(age_start >= 15 & age_start <= 60) |>
  group_by(scenario) |>
  summarise(working_age_pop = sum(pop)) |>
  arrange(working_age_pop)

cat("\n=======================================================\n")
cat("Projected Working-Age Population (15-64) in 2050:\n")
cat("=======================================================\n")
print(working_age_2050)

# ------------------------------------------------------------------------------
# 8. Data Visualization (ggplot2)
# ------------------------------------------------------------------------------

# Plot 1: Population Pyramid for the Original Data (2020 vs 2035)
# We make the male population negative to create the standard back-to-back
# pyramid shape
pyramid_data <- df_long |>
  filter(year %in% c(2020, 2035)) |>
  mutate(
    pop_plot = ifelse(sex == "male", -pop, pop),
    year_factor = as.factor(year)
  )

plot_pyramid <- ggplot(
  pyramid_data,
  aes(x = pop_plot, y = reorder(age_group, age_start), fill = sex)
) +
  geom_col() +
  facet_wrap(~year_factor) +
  scale_x_continuous(labels = abs) +
  scale_fill_manual(values = color_sex) +
  labs(
    title = "Kota Semarang Population Pyramid: 2020 vs 2035",
    subtitle = "Original BPS Projections",
    x = "Population",
    y = "Age Group",
    fill = "Sex"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(plot_pyramid)

# ggsave(filename = "img/pyramids.png", width = 8, height = 6, dpi = 320)

# Plot 2: Total Population Trajectory (2020 - 2050)
historical_totals <- df_long |>
  group_by(year) |>
  summarise(total_population = sum(pop)) |>
  mutate(scenario = "Historical (BPS)")

projected_totals <- projected_data |>
  group_by(year, scenario) |>
  summarise(total_population = sum(pop), .groups = "drop") |>
  mutate(scenario = str_to_title(scenario))

# Add the 2035 point to the projected lines so they connect seamlessly
# on the graph
bridge_point <- historical_totals |> filter(year == 2035)
for (scn in unique(projected_totals$scenario)) {
  projected_totals <- bind_rows(
    projected_totals,
    bridge_point |> mutate(scenario = scn)
  )
}

combined_totals <- bind_rows(historical_totals, projected_totals)

plot_trajectory <- ggplot(
  combined_totals,
  aes(x = year, y = total_population, color = scenario, linetype = scenario)
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = color_scenarios) +
  scale_linetype_manual(
    values = c(
      "Historical (BPS)" = "solid", "Max" = "dashed",
      "Mean" = "dashed", "Min" = "dashed"
    )
  ) +
  labs(
    title = "Total Population Projection: Kota Semarang (2020 - 2050)",
    subtitle = "Hamilton-Perry Method Scenarios",
    x = "Year",
    y = "Total Population",
    color = "Scenario",
    linetype = "Scenario"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(plot_trajectory)

# Plot 3A: Working-Age Population (15-64) Trajectory (Kota Semarang)
hist_working_age <- df_long |>
  filter(age_start >= 15 & age_start <= 60) |>
  group_by(year) |>
  summarise(working_age_pop = sum(pop)) |>
  mutate(scenario = "Historical (BPS)")

proj_working_age <- projected_data |>
  filter(age_start >= 15 & age_start <= 60) |>
  group_by(year, scenario) |>
  summarise(working_age_pop = sum(pop), .groups = "drop") |>
  mutate(scenario = str_to_title(scenario))

# Connect the working-age lines at 2035
bridge_wa <- hist_working_age |> filter(year == 2035)
for (scn in unique(proj_working_age$scenario)) {
  proj_working_age <- bind_rows(
    proj_working_age,
    bridge_wa |> mutate(scenario = scn)
  )
}

combined_wa <- bind_rows(hist_working_age, proj_working_age)

plot_wa_trajectory <- ggplot(
  combined_wa,
  aes(x = year, y = working_age_pop, color = scenario, linetype = scenario)
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = color_scenarios) +
  scale_linetype_manual(
    values = c(
      "Historical (BPS)" = "solid", "Max" = "dashed",
      "Mean" = "dashed", "Min" = "dashed"
    )
  ) +
  labs(
    title = "Working-Age Population: Kota Semarang",
    subtitle = "Hamilton-Perry Scenarios",
    x = "Year",
    y = "Population (Thousands)",
    color = "Scenario",
    linetype = "Scenario"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Plot 3B: Working-Age Population Trajectory (National UN Data)
# Load UN Dataset
# UN data reference: United Nations, Department of Economic and Social Affairs,
# Population Division (2024). World Population Prospects 2024, Online Edition.
# https://population.un.org/
un_df <- read_csv("data/Indonesia_UN_estimates.csv")

# Filter for working age (15-64) and select High/Low variants between
# 2020 and 2050
un_wa <- un_df |>
  filter(
    AgeGrpStart >= 15 & AgeGrpStart <= 60,
    Time >= 2020 & Time <= 2050,
    Variant %in% c("Momentum", "High", "Low")
  ) |>
  group_by(year = Time, scenario = Variant) |>
  summarise(working_age_pop = sum(PopTotal), .groups = "drop")

plot_un_wa_trajectory <- ggplot(
  un_wa,
  aes(x = year, y = working_age_pop, color = scenario, linetype = scenario)
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = color_scenarios) +
  scale_linetype_manual(
    values = c("Momentum" = "solid", "High" = "dashed", "Low" = "dashed")
  ) +
  labs(
    title = "Working-Age Population: Indonesia",
    subtitle = "UN Population Prospects",
    x = "Year",
    y = "Population (Thousands)",
    color = "UN Variant",
    linetype = "UN Variant"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Combine Plot 3A and 3B side-by-side using the patchwork package
combined_wa_plots <- plot_wa_trajectory + plot_un_wa_trajectory

print(combined_wa_plots)

# Optional: Export the full age-sex breakdown for 2050 to a new CSV file
# Use write_csv to write results_2050 to "Kota_Semarang_2050_Projections.csv"
cat("\nTip: Use write_csv to save the full dataset.\n")
# nolint end: object_usage_linter, indentation_linter
