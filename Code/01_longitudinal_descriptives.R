# Header ------------------------------------------------------------------
# Title: 01_longitudinal_descriptives
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Calculate group-level Yule's Q baseline-adjusted homophily 
#          across all 8 waves of NetHealth, tracing its trajectory.
#          Writes Data/longitudinal_yules_q.csv and Plots/fig-yules-q.png.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

# Load data ---------------------------------------------------------------
# load ego network survey
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))

# load basic survey
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Analysis Function --------------------------------------------------------
calc_all_waves_q <- function() {
  results <- list()
  
  for (w in paste0("Wave", 1:8)) {
    # Clean and merge for the specific wave
    df_w <- df_netsurv |> 
      filter(wave == w) |>
      left_join(df_basicsurv, by = "egoid") |>
      filter(!is.na(yourelig_1)) |>
      filter(altrelucat == "Student") |>
      filter(family == FALSE) |> # exclude on-campus family ties (e.g. siblings), keep only non-family student ties
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
    
    # Construct mixing matrix
    groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")
    m <- matrix(0, nrow = 4, ncol = 4, dimnames = list(groups, groups))
    
    counts <- df_w |> count(ego_rel, alt_rel)
    for (i in seq_len(nrow(counts))) {
      m[counts$ego_rel[i], counts$alt_rel[i]] <- counts$n[i]
    }
    
    # Calculate Yule's Q for each group
    for (g in groups) {
      a <- m[g, g]
      b <- sum(m[g, setdiff(groups, g)])
      c <- sum(m[setdiff(groups, g), g])
      d <- sum(m[setdiff(groups, g), setdiff(groups, g)])
      
      # Avoid division by zero
      if ((a * d + b * c) == 0) {
        q <- NA
      } else {
        q <- (a * d - b * c) / (a * d + b * c)
      }
      
      results[[length(results) + 1]] <- data.frame(
        Wave = w,
        Group = g,
        a = a,
        b = b,
        c = c,
        d = d,
        Yules_Q = q,
        stringsAsFactors = FALSE
      )
    }
  }
  
  bind_rows(results)
}

# Run calculation ---------------------------------------------------------
df_q_waves <- calc_all_waves_q()

# Save results
write_csv(df_q_waves, here("Data", "longitudinal_yules_q.csv"))

cat("\nLongitudinal Yule's Q trajectories successfully calculated and saved to Data/longitudinal_yules_q.csv.\n")

# Create Plot -------------------------------------------------------------
df_plot <- df_q_waves |>
  mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))

# Generate plot of homophily trajectory
ggplot(df_plot, aes(x = Wave_Num, y = Yules_Q, color = Group, group = Group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_x_continuous(breaks = 1:8, labels = paste0("W", 1:8)) +
  labs(
    title = "Religious Homophily Trajectory (NetHealth Cohort)",
    subtitle = "Baseline-adjusted group-level Yule's Q across 8 Waves",
    x = "Study Wave",
    y = "Yule's Q (Homophily)",
    color = "Religious Group"
  ) +
  theme_minimal() +
  ylim(0, 1)

# Save Plot
ggsave(here("Plots", "fig-yules-q.png"), width = 7, height = 4.5, dpi = 300)
cat("Yule's Q trajectory plot successfully generated and saved to Plots/fig-yules-q.png\n")
