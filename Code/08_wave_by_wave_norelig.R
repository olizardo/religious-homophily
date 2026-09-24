# Header ------------------------------------------------------------------
# Title: 08_wave_by_wave_norelig
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Purpose: Investigate why the No Religion group shows a null opportunity-
#          adjusted homophily effect at the Wave 3 cross-section (see
#          Code/02_dyadic_models.R) but a significant effect in the pooled
#          Waves 3-8 model (see Code/02_dyadic_models_pooled.R). Refits the
#          pooled Model 2 specification (structural + salience controls,
#          no degree terms) separately for each wave, for all three
#          non-Catholic groups, to distinguish a genuine wave-3-specific
#          pattern from a simple statistical-power artifact. Also fits a
#          clustered ego_rel x wave interaction on the full pooled data as
#          a formal trend test. This script is the reproducible source for
#          the wave-by-wave claims added to the Discussion section of
#          paper.tex on 2026-09-24 (see AGENTS.md Section 8).

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(broom)
library(sandwich)
library(lmtest)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'), show_col_types = FALSE)
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'), show_col_types = FALSE)

waves <- paste0("Wave", 3:8)

# Degree Measures (computed but not used in the Model 2 spec here; kept for
# parity with 02_dyadic_models_pooled.R in case a Model 3 (+degree) refit is
# wanted later) ------------------------------------------------------------
ego_degree_all <- df_netsurv |>
  filter(wave %in% waves) |>
  count(wave, egoid, name = "ego_out_degree")

alter_pop_all <- df_netsurv |>
  filter(wave %in% waves) |>
  count(wave, alterid, name = "alter_popularity")

# Prepare Pooled Long-Format Dyadic Dataset (Waves 3-8) --------------------
# This block is a deliberate copy of Code/02_dyadic_models_pooled.R's data
# prep, so results here line up exactly with the pooled regression table.
df_all <- df_netsurv |>
  filter(wave %in% waves) |>
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

wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop = n / sum(n)) |>
  ungroup()

df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  left_join(ego_degree_all, by = c("wave", "egoid")) |>
  left_join(alter_pop_all, by = c("wave", "alterid")) |>
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
    discuss_num = case_when(
      discussrelig_2 == "Not at all" ~ 1,
      discussrelig_2 == "Less than 1-2 times a month" ~ 2,
      discussrelig_2 == "1-2 times a month" ~ 3,
      discussrelig_2 == "1-2 times a week" ~ 4,
      discussrelig_2 == "Three times a week or more" ~ 5,
      TRUE ~ NA_real_
    ),
    log_ego_degree = log(ego_out_degree),
    log_alter_pop = log1p(alter_popularity),
    close_num = case_when(
      close == "Distant" ~ 1,
      close == "LessThanClose" ~ 2,
      close == "MerelyClose" ~ 3,
      close == "EspeciallyClose" ~ 4,
      TRUE ~ NA_real_
    ),
    wave_num = as.numeric(sub("Wave", "", wave))
  ) |>
  filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender),
         !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(close_num),
         !is.na(discuss_num), !is.na(log_ego_degree), !is.na(log_alter_pop))

# Per-Wave Model 2 Refits (Structural + Salience Controls, No Degree) -----
# Same formula as Model 2 in Code/02_dyadic_models_pooled.R, but fit
# separately within each wave rather than pooled, so each wave's point
# estimate and precision can be inspected on its own.
fit_group_by_wave <- function(w, grp) {
  d <- df_pooled |> filter(wave == w)
  m <- tryCatch(
    glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num,
        family = binomial,
        offset = opportunity_offset,
        data = d),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)
  term_name <- paste0("ego_rel", grp)
  broom::tidy(m) |>
    filter(term == term_name) |>
    mutate(wave = w, group = grp)
}

groups <- c("No Religion", "Protestant", "Other Religion")

per_wave_coefs <- bind_rows(
  lapply(groups, function(g) bind_rows(lapply(waves, fit_group_by_wave, grp = g)))
) |>
  select(group, wave, estimate, std.error, statistic, p.value)

# Descriptive Sample Sizes and Observed vs. Baseline Rates by Group/Wave --
desc_by_group_wave <- function(grp) {
  df_pooled |>
    filter(ego_rel == grp) |>
    group_by(wave) |>
    summarise(
      n_ties = n(),
      n_egos = n_distinct(egoid),
      obs_same_rate = mean(same_religion),
      baseline_prop = mean(plogis(opportunity_offset)),
      excess = obs_same_rate - baseline_prop,
      .groups = "drop"
    ) |>
    mutate(group = grp)
}

per_wave_desc <- bind_rows(lapply(groups, desc_by_group_wave)) |>
  select(group, wave, n_egos, n_ties, obs_same_rate, baseline_prop, excess)

# Combine coefficients and descriptives into one table for reporting -----
per_wave_summary <- per_wave_desc |>
  left_join(per_wave_coefs, by = c("group", "wave")) |>
  arrange(factor(group, levels = groups), factor(wave, levels = waves))

cat("\n======================================================\n")
cat("Per-wave Model 2 coefficients and descriptives by religious group\n")
cat("======================================================\n")
print(per_wave_summary, n = Inf)

# Formal Trend Test: ego_rel x wave_num Interaction (Clustered SEs) -------
# Tests whether the apparent rise in the No Religion coefficient across
# waves (and the flatness for Protestant/Other Religion) reflects a
# statistically distinguishable linear trend, or is consistent with no
# trend given the small and shrinking number of unique egos per group.
model_interaction <- glm(
  same_religion ~ ego_rel * wave_num + same_gender + same_race + roommates + samedorm + close_num + discuss_num,
  family = binomial,
  offset = opportunity_offset,
  data = df_pooled
)

interaction_clustered <- coeftest(model_interaction, vcov = vcovCL(model_interaction, cluster = df_pooled$egoid))

cat("\n======================================================\n")
cat("Clustered ego_rel x wave_num interaction terms (trend test)\n")
cat("======================================================\n")
print(interaction_clustered[grepl(":wave_num", rownames(interaction_clustered)), , drop = FALSE])

# Save Results --------------------------------------------------------------
saveRDS(
  list(
    per_wave_summary = per_wave_summary,
    interaction_model = model_interaction,
    interaction_clustered = interaction_clustered
  ),
  here("Data", "wave_by_wave_norelig_results.RDS")
)

write_csv(per_wave_summary, here("Data", "wave_by_wave_norelig_summary.csv"))

cat("\nSaved: Data/wave_by_wave_norelig_results.RDS, Data/wave_by_wave_norelig_summary.csv\n")
