# Header ------------------------------------------------------------------
# Title: 02_dyadic_models_interaction
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Revised: 2026-10-23 - primary (cohort) and sensitivity (alter-pool) offsets;
#          leave-focal-tie-out alter popularity; joint Wald test of group x wave.
# Purpose: Fit dyadic logistic regression models interacting wave with religious
#          group to test whether opportunity-adjusted minority homophily changes
#          over Waves 3-8, using ego-clustered robust standard errors.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(sandwich)
library(lmtest)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")

# Degree measures (Reviewer 1: activity/popularity confound) ---------------
ego_degree_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  count(wave, egoid, name = "ego_out_degree")

alter_pop_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  count(wave, alterid, name = "alter_popularity")

# Prepare pooled dataset (Waves 3-8) --------------------------------------
df_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
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
  filter(
    ego_rel %in% groups,
    alt_rel %in% groups
  )

# Opportunity baselines (same definitions as Code/02_dyadic_models_pooled.R)
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

# Merge proportions and construct dyadic variables
df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop_pool), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  left_join(cohort_props, by = "ego_rel") |>
  left_join(ego_degree_all, by = c("wave", "egoid")) |>
  left_join(alter_pop_all, by = c("wave", "alterid")) |>
  mutate(
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    offset_cohort = log(prop_cohort / (1 - prop_cohort)),
    offset_pool = log(prop_pool / (1 - prop_pool)),

    same_gender = ifelse(gender_1 == altsex, 1, 0),
    # Unknown alter race stays NA (dropped by the complete-case filter), not 0
    same_race = case_when(
      race_1 == "White" ~ as.numeric(altwhite),
      race_1 == "African-American" ~ as.numeric(altblack),
      race_1 == "Asian-American" ~ as.numeric(altasian),
      race_1 == "Latino/a" ~ as.numeric(althisla),
      TRUE ~ NA_real_
    ),

    # Continuous wave (Wave 3 = 0), so main effects are at Wave 3
    wave_num = as.numeric(gsub("Wave", "", wave)) - 3,

    # Degree controls (see Code/02_dyadic_models_pooled.R)
    log_ego_degree = log(ego_out_degree),
    log_alter_pop = log1p(alter_popularity - 1),

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
  filter(!is.na(same_religion), !is.na(offset_cohort), !is.na(offset_pool),
         !is.na(same_gender), !is.na(same_race), !is.na(roommates), !is.na(samedorm),
         !is.na(discuss_num), !is.na(log_ego_degree), !is.na(log_alter_pop), !is.na(close_num))

cat("Fitting interaction models on", nrow(df_pooled), "ties across", n_distinct(df_pooled$egoid), "unique egos...\n")

# Fit interaction models ----------------------------------------------------
int_formula <- same_religion ~ ego_rel * wave_num + same_gender + same_race + roommates + samedorm + close_num + discuss_num + log_ego_degree + log_alter_pop

model_interaction <- glm(int_formula, family = binomial, offset = offset_cohort, data = df_pooled)
model_interaction_pool <- glm(int_formula, family = binomial, offset = offset_pool, data = df_pooled)

vcov_int <- vcovCL(model_interaction, cluster = df_pooled$egoid)
vcov_int_pool <- vcovCL(model_interaction_pool, cluster = df_pooled$egoid)

clustered_results <- coeftest(model_interaction, vcov = vcov_int)
clustered_results_pool <- coeftest(model_interaction_pool, vcov = vcov_int_pool)

# Joint Wald test of all group x wave terms (3 df), ego-clustered vcov ------
joint_wald <- function(model, vcov_mat) {
  idx <- grep(":wave_num", names(coef(model)))
  b <- coef(model)[idx]
  W <- as.numeric(t(b) %*% solve(vcov_mat[idx, idx, drop = FALSE]) %*% b)
  tibble::tibble(
    df = length(idx),
    chisq = W,
    p_value = pchisq(W, df = length(idx), lower.tail = FALSE)
  )
}

wald_group_wave <- dplyr::bind_rows(
  cohort = joint_wald(model_interaction, vcov_int),
  pool = joint_wald(model_interaction_pool, vcov_int_pool),
  .id = "baseline"
)

cat("\n========================================================================\n")
cat("INTERACTION MODEL (cohort offset, primary): clustered SE\n")
cat("========================================================================\n")
print(clustered_results)

cat("\n========================================================================\n")
cat("INTERACTION MODEL (alter-pool offset, sensitivity): clustered SE\n")
cat("========================================================================\n")
print(clustered_results_pool)

cat("\n--- Joint Wald test: all group x wave terms ---\n")
print(wald_group_wave)

saveRDS(clustered_results, here("Data", "interaction_model_results.RDS"))
saveRDS(list(results = clustered_results_pool, joint_wald = wald_group_wave),
        here("Data", "interaction_model_results_pool.RDS"))
