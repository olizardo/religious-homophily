# Header ------------------------------------------------------------------
# Title: 05_plot_active_coefficients
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Generate a grouped line plot tracking the wave-specific 
#          active (opportunity-adjusted) religious homophily coefficients 
#          across Waves 3 to 8 of the NetHealth cohort, demonstrating 
#          the durability and relative heights of the social boundaries.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

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

# Calculate wave-specific alter religious proportions (opportunity pool)
wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop = n / sum(n)) |>
  ungroup()

# Merge proportions and construct dyadic variables
df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  mutate(
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    opportunity_offset = log(prop / (1 - prop)),
    same_gender = ifelse(gender_1 == altsex, 1, 0),
    same_race = case_when(
      race_1 == "White" & altwhite == TRUE ~ 1,
      race_1 == "African-American" & altblack == TRUE ~ 1,
      race_1 == "Asian-American" & altasian == TRUE ~ 1,
      race_1 == "Latino/a" & althisla == TRUE ~ 1,
      race_1 %in% c("White", "African-American", "Asian-American", "Latino/a") ~ 0,
      TRUE ~ NA_real_
    ),
    close_num = case_when(
      close == "Distant" ~ 1,
      close == "LessThanClose" ~ 2,
      close == "MerelyClose" ~ 3,
      close == "EspeciallyClose" ~ 4,
      TRUE ~ NA_real_
    )
  ) |>
  filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender), 
         !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(close_num))

# Extract active homophily coefficients wave-by-wave
coef_results <- list()

for (w in paste0("Wave", 3:8)) {
  df_w <- df_pooled |> filter(wave == w)
  
  model <- glm(
    same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num, 
    family = binomial, 
    offset = opportunity_offset, 
    data = df_w
  )
  
  coefs <- coef(model)
  b0 <- coefs["(Intercept)"]
  b_none <- coefs["ego_relNo Religion"]
  b_other <- coefs["ego_relOther Religion"]
  b_prot <- coefs["ego_relProtestant"]
  
  coef_results[[w]] <- bind_rows(
    data.frame(Wave = w, Group = "Catholic", Coefficient = b0),
    data.frame(Wave = w, Group = "No Religion", Coefficient = b0 + b_none),
    data.frame(Wave = w, Group = "Other Religion", Coefficient = b0 + b_other),
    data.frame(Wave = w, Group = "Protestant", Coefficient = b0 + b_prot)
  )
}

df_coef_plot <- bind_rows(coef_results) |>
  mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))

# Generate Plot
ggplot(df_coef_plot, aes(x = Wave_Num, y = Coefficient, color = Group, group = Group)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  labs(
    title = "Active (Opportunity-Adjusted) Religious Homophily Coefficients",
    subtitle = "Wave-specific log-odds ratios of ingroup friendship choices (Waves 3-8)",
    x = "Study Wave",
    y = "Active Homophily Coefficient (Log-Odds)",
    color = "Religious Group"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    panel.grid.minor = element_blank()
  )

# Save Plot
ggsave(here("Plots", "plot_active_homophily_coefficients.png"), width = 7, height = 4.5, dpi = 300)
cat("Active homophily coefficients plot successfully generated and saved to Plots/plot_active_homophily_coefficients.png\n")
