# Header ------------------------------------------------------------------
# Title: 09_plot_wave_by_wave_norelig
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Purpose: Plot the per-wave opportunity-adjusted homophily coefficients
#          (with 95% CIs) for the three non-Catholic groups, from the
#          wave-by-wave refits in Code/08_wave_by_wave_norelig.R. Visualizes
#          the pattern discussed in paper.tex's Discussion section: No
#          Religion starts statistically null at Wave 3 and rises across
#          Waves 4-8, while Protestant and Other Religion are already
#          significant at Wave 3 and stay roughly flat.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(ggplot2)

# Load per-wave summary --------------------------------------------------
# Regenerate here (rather than just reading the CSV) so this plot always
# reflects a fresh model fit; re-run Code/08_wave_by_wave_norelig.R first if
# you only want to refresh the CSV/RDS without replotting.
if (!file.exists(here("Data", "wave_by_wave_norelig_summary.csv"))) {
  source(here("Code", "08_wave_by_wave_norelig.R"))
}

df_plot <- read_csv(here("Data", "wave_by_wave_norelig_summary.csv"), show_col_types = FALSE) |>
  mutate(
    wave_num = as.numeric(sub("Wave", "", wave)),
    group = factor(group, levels = c("No Religion", "Protestant", "Other Religion")),
    ci_lower = estimate - 1.96 * std.error,
    ci_upper = estimate + 1.96 * std.error
  )

# Generate Plot -------------------------------------------------------------
ggplot(df_plot, aes(x = wave_num, y = estimate, color = group)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_line(aes(group = group), linewidth = 1, position = position_dodge(width = 0.3)) +
  geom_pointrange(
    aes(ymin = ci_lower, ymax = ci_upper),
    position = position_dodge(width = 0.3),
    size = 0.6
  ) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  labs(
    title = "Wave-Specific Opportunity-Adjusted Homophily Coefficients by Group",
    subtitle = "Non-Catholic groups relative to the Catholic baseline (Model 2 spec: structural + salience controls)",
    x = "Study Wave",
    y = "Coefficient (log-odds, \u00b1 95% CI)",
    color = "Religious Group"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 9),
    panel.grid.minor = element_blank()
  )

# Save Plot -------------------------------------------------------------
ggsave(here("Plots", "fig-wave-by-wave-norelig.png"), width = 7.5, height = 5, dpi = 300)
cat("Saved: Plots/fig-wave-by-wave-norelig.png\n")
