# Header ------------------------------------------------------------------
# Title: 05_plot_active_coefficients
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Revised: 2026-10-23 - three versions of Figure 3 from the same wave-specific models:
#          (1) primary: ego-cohort offset, offset fixed at 0 (Plots/fig-active-coefs.png);
#          (2) sensitivity: alter-pool offset, offset fixed at 0 (fig-active-coefs-pool.png);
#          (3) cohort offset at each tie's observed value (fig-active-coefs-observed.png).
#          Covariates now match Model 2 (religious salience included). Ego-clustered CIs.
#          The header "durability" wording is withdrawn: no analysis here tests durability.
# Purpose: Plot wave-specific average marginal effects (probability scale) of
#          non-Catholic religious affiliation on same-religion tie formation, Waves 3-8.
#
#          Each wave is a separate cross-sectional logit with the Model 2 covariates
#          and the opportunity offset. Each estimate is averaged over all observed
#          ties in that wave (marginaleffects::avg_comparisons). Offset-at-zero
#          versions are a counterfactual (every group at a 50% share); their
#          magnitudes depend on that counterfactual and are not comparable to Table 1
#          log-odds coefficients.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(marginaleffects)

groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")
waves <- paste0("Wave", 3:8)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Prepare data ------------------------------------------------------------
df_all <- df_netsurv |>
  filter(wave %in% waves) |>
  left_join(df_basicsurv, by = "egoid") |>
  filter(!is.na(yourelig_1)) |>
  filter(altrelucat == "Student") |>
  filter(family == FALSE) |> # exclude on-campus family ties (e.g. siblings)
  filter(!is.na(altrelig)) |>
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(
      altrelig == "NoReligion" ~ "No Religion",
      altrelig == "OtherReligion" ~ "Other Religion",
      TRUE ~ altrelig
    )
  ) |>
  filter(ego_rel %in% groups, alt_rel %in% groups)

cohort_props <- df_basicsurv |>
  mutate(ego_rel = as.character(yourelig_1)) |>
  filter(ego_rel %in% groups) |>
  count(ego_rel, name = "n_cohort") |>
  mutate(prop_cohort = n_cohort / sum(n_cohort)) |>
  select(ego_rel, prop_cohort)

wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop_pool = n / sum(n)) |>
  ungroup()

df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop_pool), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  left_join(cohort_props, by = "ego_rel") |>
  mutate(
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    offset_cohort = log(prop_cohort / (1 - prop_cohort)),
    offset_pool = log(prop_pool / (1 - prop_pool)),
    # Catholic as the reference level
    ego_rel = factor(ego_rel, levels = groups),
    same_gender = ifelse(gender_1 == altsex, 1, 0),
    # Unknown alter race stays NA (dropped by the complete-case filter), not 0
    same_race = case_when(
      race_1 == "White" ~ as.numeric(altwhite),
      race_1 == "African-American" ~ as.numeric(altblack),
      race_1 == "Asian-American" ~ as.numeric(altasian),
      race_1 == "Latino/a" ~ as.numeric(althisla),
      TRUE ~ NA_real_
    ),
    discuss_num = case_when(
      discussrelig_2 == "Not at all" ~ 1,
      discussrelig_2 == "Less than 1-2 times a month" ~ 2,
      discussrelig_2 == "1-2 times a month" ~ 3,
      discussrelig_2 == "1-2 times a week" ~ 4,
      discussrelig_2 == "Three times a week or more" ~ 5,
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
  filter(!is.na(same_religion), !is.na(offset_cohort), !is.na(offset_pool), !is.na(same_gender),
         !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(discuss_num), !is.na(close_num))

# Wave-specific average marginal effects -----------------------------------
# offset_name: which baseline enters the fit. at_zero: TRUE sets the offset to 0
# in the prediction grid (counterfactual); FALSE keeps each tie's observed offset.
wave_me <- function(w, offset_name, at_zero) {
  df_w <- df_pooled |>
    filter(wave == w) |>
    mutate(opp_offset = .data[[offset_name]])

  model <- glm(
    same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num + offset(opp_offset),
    family = binomial,
    data = df_w
  )

  nd <- df_w |> select(ego_rel, same_gender, same_race, roommates, samedorm, close_num, discuss_num, opp_offset)
  if (at_zero) nd <- nd |> mutate(opp_offset = 0)

  cmp <- avg_comparisons(
    model,
    variables = list(ego_rel = "reference"),
    vcov = ~egoid,
    newdata = nd
  ) |>
    as.data.frame() |>
    mutate(Group = gsub(" - Catholic", "", contrast))

  n_egos <- df_w |>
    group_by(ego_rel) |>
    summarise(n_egos = n_distinct(egoid), .groups = "drop") |>
    rename(Group = ego_rel) |>
    mutate(Group = as.character(Group))

  cmp |>
    left_join(n_egos, by = "Group") |>
    transmute(
      Wave = w,
      Group,
      Estimate = estimate,
      conf.low,
      conf.high,
      n_egos
    )
}

settings <- list(
  cohort_zero = list(offset = "offset_cohort", at_zero = TRUE),
  pool_zero = list(offset = "offset_pool", at_zero = TRUE),
  cohort_observed = list(offset = "offset_cohort", at_zero = FALSE)
)

me_all <- bind_rows(lapply(names(settings), function(s) {
  bind_rows(lapply(waves, wave_me, offset_name = settings[[s]]$offset, at_zero = settings[[s]]$at_zero)) |>
    mutate(Setting = s, .before = 1)
}))

me_all |>
  mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave))) |>
  write_csv(here("Data", "active_coefs_me.csv"))

# Plot -------------------------------------------------------------------
plot_me <- function(setting, subtitle) {
  d <- me_all |>
    filter(Setting == setting) |>
    mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))
  ggplot(d, aes(x = Wave_Num, y = Estimate, color = Group, group = Group)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.15,
                  position = position_dodge(width = 0.3)) +
    geom_line(linewidth = 1, position = position_dodge(width = 0.3)) +
    geom_point(size = 2.5, position = position_dodge(width = 0.3)) +
    scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
    labs(
      title = "Average Marginal Effects of Religious Affiliation on Active Homophily",
      subtitle = subtitle,
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
}

ggsave(here("Plots", "fig-active-coefs.png"),
       plot_me("cohort_zero", "Ego-cohort offset, equal-opportunity counterfactual (offset = 0), Waves 3-8. 95% CIs ego-clustered."),
       width = 7, height = 4.5, dpi = 300)
ggsave(here("Plots", "fig-active-coefs-pool.png"),
       plot_me("pool_zero", "Nominated-alter pool offset, equal-opportunity counterfactual (offset = 0), Waves 3-8. 95% CIs ego-clustered."),
       width = 7, height = 4.5, dpi = 300)
ggsave(here("Plots", "fig-active-coefs-observed.png"),
       plot_me("cohort_observed", "Ego-cohort offset at each tie's observed value, Waves 3-8. 95% CIs ego-clustered."),
       width = 7, height = 4.5, dpi = 300)

cat("Figure 3 versions saved to Plots/fig-active-coefs*.png; estimates and ego counts in Data/active_coefs_me.csv\n")
