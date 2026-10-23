# Header ------------------------------------------------------------------
# Title: 05_plot_active_coefficients
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Revised: 2026-10-22 - Figure 3 now plots true average marginal effects (avg over
#          all observed ties per wave, offset fixed at 0; covariates = Model 2 minus
#          religious salience) and the offset is written as offset() in the formula.
# Revised: 2026-10-01 - switched from plotting raw wave-specific log-odds
#          coefficients to genuine probability-scale marginal effects
#          (marginaleffects::avg_comparisons, opportunity offset held at 0),
#          to match the methodological description in paper.tex's Primary
#          Analysis section (the "equal-opportunity" marginal-effects
#          paragraph). Each estimate is the excess probability of a
#          same-religion tie for a given non-Catholic group vs. the
#          Catholic baseline, under a counterfactual in which the
#          opportunity offset is fixed at 0 (i.e., as if every religious
#          group had equal representation in the opportunity pool that
#          wave), computed separately in cross-section for each wave.
# Purpose: Generate a plot tracking the wave-specific marginal effects of
#          non-Catholic religious affiliation on active homophily across
#          Waves 3 to 8 of the NetHealth cohort, demonstrating the
#          durability and relative heights of the social boundaries.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(marginaleffects)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Prepare Data ------------------------------------------------------------
df_all <- df_netsurv |> 
  filter(wave %in% paste0("Wave", 3:8)) |>
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
    # Catholic as the reference level, so marginaleffects' "reference"
    # contrasts are always each non-Catholic group vs. Catholic.
    ego_rel = factor(ego_rel, levels = c("Catholic", "No Religion", "Other Religion", "Protestant")),
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

# Compute wave-by-wave probability-scale average marginal effects -----------
# For each wave, fit a cross-sectional opportunity-adjusted logistic regression
# with the Model 2 covariates excluding religious salience (discuss_num), then
# use marginaleffects::avg_comparisons() to average each non-Catholic group's
# contrast with Catholic over all observed ties in that wave. The opportunity
# offset is set to 0 in the prediction grid (the "equal-opportunity" scenario:
# each group has a 50% share), and the other covariates keep their observed
# values for each tie.
me_results <- list()

for (w in paste0("Wave", 3:8)) {
  df_w <- df_pooled |> filter(wave == w)
  
  model <- glm(
    same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + offset(opportunity_offset),
    family = binomial,
    data = df_w
  )
  
  cmp <- avg_comparisons(
    model,
    variables = list(ego_rel = "reference"),
    newdata = df_w |>
      select(ego_rel, same_gender, same_race, roommates, samedorm, close_num) |>
      mutate(opportunity_offset = 0)
  ) |>
    as.data.frame() |>
    mutate(Group = gsub(" - Catholic", "", contrast))
  
  me_results[[w]] <- data.frame(
    Wave = w,
    Group = cmp$Group,
    Estimate = cmp$estimate,
    conf.low = cmp$conf.low,
    conf.high = cmp$conf.high
  )
}

df_me_plot <- bind_rows(me_results) |>
  mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))

# Generate Plot -------------------------------------------------------------
ggplot(df_me_plot, aes(x = Wave_Num, y = Estimate, color = Group, group = Group)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.15,
                position = position_dodge(width = 0.3)) +
  geom_line(linewidth = 1, position = position_dodge(width = 0.3)) +
  geom_point(size = 2.5, position = position_dodge(width = 0.3)) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  labs(
    title = "Marginal Effects of Religious Affiliation on Active Homophily",
    subtitle = "Excess probability of a same-religion tie vs. Catholic baseline,\nequal-opportunity scenario (Waves 3-8)",
    x = "Study Wave",
    y = "Marginal Effect\n(Excess Probability vs. Catholic)",
    color = "Religious Group"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    panel.grid.minor = element_blank()
  )

# Save Plot
ggsave(here("Plots", "fig-active-coefs.png"), width = 7, height = 4.5, dpi = 300)
cat("Marginal-effects active homophily plot successfully generated and saved to Plots/fig-active-coefs.png\n")
