# Header ------------------------------------------------------------------
# Title: 04_plot_opportunity_stability
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Generate a grouped line plot tracking the wave-specific 
#          religious proportions in the available alter pool (Waves 3-8), 
#          visually demonstrating the high stability of the cohort's 
#          religious opportunity structure.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey(2-28-20).csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey(3-6-20).csv'))

# Prepare Data ------------------------------------------------------------
df_all <- df_netsurv |> 
  filter(wave %in% paste0("Wave", 3:8)) |>
  left_join(df_basicsurv, by = "egoid") |>
  filter(!is.na(yourelig_1)) |>
  filter(altrelucat == "Student") |>
  filter(!is.na(altrelig)) |>
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(
      altrelig == "NoReligion" ~ "No Religion",
      altrelig == "OtherReligion" ~ "Other Religion",
      TRUE ~ altrelig
    )
  ) |>
  filter(
    ego_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"),
    alt_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant")
  )

# Calculate wave-specific alter proportions
wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop = n / sum(n)) |>
  ungroup() |>
  mutate(Wave_Num = as.numeric(gsub("Wave", "", wave)))

# Create Plot -------------------------------------------------------------
ggplot(wave_alter_props, aes(x = Wave_Num, y = prop, color = alt_rel, group = alt_rel)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(
    title = "Religious Opportunity Pool Stability (NetHealth Cohort)",
    subtitle = "Wave-specific proportions of available alters (Waves 3-8)",
    x = "Study Wave",
    y = "Proportion of Alter Pool",
    color = "Religious Group"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    panel.grid.minor = element_blank()
  )

# Save Plot
ggsave(here("plot_opportunity_pool_stability.png"), width = 7, height = 4.5, dpi = 300)
cat("Opportunity stability plot successfully generated and saved to plot_opportunity_pool_stability.png\n")
