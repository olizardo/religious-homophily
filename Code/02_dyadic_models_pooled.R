# Header ------------------------------------------------------------------
# Title: 02_dyadic_models_pooled
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Revised: 2026-10-23 - two opportunity baselines. Primary ("cohort"): ego-cohort
#          religious composition (Wave 1, all egos with religion known). Sensitivity
#          ("pool"): wave-specific composition of nominated student alters. Alter
#          popularity is leave-focal-tie-out (in-degree minus the focal nomination).
# Purpose: Fit pooled longitudinal dyadic logistic regression models across Waves
#          3 to 8 of the NetHealth cohort, using ego-clustered robust standard errors.

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
# Computed per wave on the FULL nomination roster (before filtering to Student
# alters with known religion). The focal nomination is included in both counts.
ego_degree_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  count(wave, egoid, name = "ego_out_degree")

alter_pop_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  count(wave, alterid, name = "alter_popularity")

# Prepare pooled long-format dyadic dataset (Waves 3-8) -------------------
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

# Opportunity baselines ----------------------------------------------------
# Primary ("cohort"): religious composition of all egos with religion known,
# Wave 1. Time-invariant, so the offset is constant within group across waves.
cohort_props <- df_basicsurv |>
  mutate(ego_rel = as.character(yourelig_1)) |>
  filter(ego_rel %in% groups) |>
  count(ego_rel, name = "n_cohort") |>
  mutate(prop_cohort = n_cohort / sum(n_cohort)) |>
  select(ego_rel, prop_cohort)

# Sensitivity ("pool"): wave-specific composition of nominated student alters
wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop_pool = n / sum(n)) |>
  ungroup()

cat("Opportunity baseline, ego cohort (primary):\n")
print(cohort_props)

# Merge proportions and construct dyadic variables
df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop_pool), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  left_join(cohort_props, by = "ego_rel") |>
  left_join(ego_degree_all, by = c("wave", "egoid")) |>
  left_join(alter_pop_all, by = c("wave", "alterid")) |>
  mutate(
    # Outcome: whether tie is homophilous
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),

    # Opportunity offsets: log-odds of the ego's group share under each baseline
    offset_cohort = log(prop_cohort / (1 - prop_cohort)),
    offset_pool = log(prop_pool / (1 - prop_pool)),

    # Alternative homophily dimensions
    same_gender = ifelse(gender_1 == altsex, 1, 0),
    # Unknown alter race stays NA (dropped by the complete-case filter), not 0
    same_race = case_when(
      race_1 == "White" ~ as.numeric(altwhite),
      race_1 == "African-American" ~ as.numeric(altblack),
      race_1 == "Asian-American" ~ as.numeric(altasian),
      race_1 == "Latino/a" ~ as.numeric(althisla),
      TRUE ~ NA_real_
    ),
    # Discussion frequency as a proxy for individual religious salience
    discuss_num = case_when(
      discussrelig_2 == "Not at all" ~ 1,
      discussrelig_2 == "Less than 1-2 times a month" ~ 2,
      discussrelig_2 == "1-2 times a month" ~ 3,
      discussrelig_2 == "1-2 times a week" ~ 4,
      discussrelig_2 == "Three times a week or more" ~ 5,
      TRUE ~ NA_real_
    ),

    # Ego activity: log out-degree (>= 1, since the focal nomination is counted).
    # Alter popularity: log(1 + in-degree excluding the focal nomination), so the
    # focal tie does not count toward its own popularity covariate.
    log_ego_degree = log(ego_out_degree),
    log_alter_pop = log1p(alter_popularity - 1),

    # Intimacy control
    close_num = case_when(
      close == "Distant" ~ 1,
      close == "LessThanClose" ~ 2,
      close == "MerelyClose" ~ 3,
      close == "EspeciallyClose" ~ 4,
      TRUE ~ NA_real_
    )
  )

# Filter to complete cases for modeling (identical sample for both baselines)
df_pooled_clean <- df_pooled |>
  filter(!is.na(same_religion), !is.na(offset_cohort), !is.na(offset_pool),
         !is.na(same_gender), !is.na(same_race), !is.na(roommates), !is.na(samedorm),
         !is.na(discuss_num), !is.na(log_ego_degree), !is.na(log_alter_pop), !is.na(close_num))

cat("Total pooled ties for regression (Waves 3-8):", nrow(df_pooled_clean), "\n")
cat("Number of unique egos:", n_distinct(df_pooled_clean$egoid), "\n\n")

# Fit pooled models: primary (cohort offset) ------------------------------
model1_pooled <- glm(same_religion ~ ego_rel,
                     family = binomial,
                     offset = offset_cohort,
                     data = df_pooled_clean)

model2_pooled <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num,
                     family = binomial,
                     offset = offset_cohort,
                     data = df_pooled_clean)

model3_pooled <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num + log_ego_degree + log_alter_pop,
                     family = binomial,
                     offset = offset_cohort,
                     data = df_pooled_clean)

# Fit pooled models: sensitivity (alter-pool offset) ------------------------
model1_pool <- glm(same_religion ~ ego_rel,
                   family = binomial,
                   offset = offset_pool,
                   data = df_pooled_clean)

model2_pool <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num,
                   family = binomial,
                   offset = offset_pool,
                   data = df_pooled_clean)

model3_pool <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num + log_ego_degree + log_alter_pop,
                   family = binomial,
                   offset = offset_pool,
                   data = df_pooled_clean)

# Clustered robust standard errors (cluster on egoid) ------------------------
# Accounts for the nesting of multiple ties within egos and repeated waves.
cl_test <- function(m) coeftest(m, vcov = vcovCL(m, cluster = df_pooled_clean$egoid))

m1_clustered <- cl_test(model1_pooled)
m2_clustered <- cl_test(model2_pooled)
m3_clustered <- cl_test(model3_pooled)

m1_pool_clustered <- cl_test(model1_pool)
m2_pool_clustered <- cl_test(model2_pool)
m3_pool_clustered <- cl_test(model3_pool)

cat("========================================================================\n")
cat("POOLED MODEL 1 (cohort offset, primary): clustered SE\n")
cat("========================================================================\n")
print(m1_clustered)

cat("\n========================================================================\n")
cat("POOLED MODEL 2 (cohort offset, primary): clustered SE\n")
cat("========================================================================\n")
print(m2_clustered)

cat("\n========================================================================\n")
cat("POOLED MODEL 3 (cohort offset, primary): clustered SE\n")
cat("========================================================================\n")
print(m3_clustered)

cat("\n========================================================================\n")
cat("SENSITIVITY: Models 1-3 with alter-pool offset (clustered SE)\n")
cat("========================================================================\n")
print(m1_pool_clustered)
print(m2_pool_clustered)
print(m3_pool_clustered)

cat("\n--- Mean ego out-degree by religious group (pooled Waves 3-8) ---\n")
df_pooled_clean |>
  group_by(ego_rel) |>
  summarise(mean_ego_out_degree = mean(ego_out_degree, na.rm = TRUE), .groups = "drop") |>
  print()

# Save clustered tables to disk ---------------------------------------------
saveRDS(
  list(
    model1 = m1_clustered, model2 = m2_clustered, model3 = m3_clustered,
    model1_pool = m1_pool_clustered, model2_pool = m2_pool_clustered, model3_pool = m3_pool_clustered
  ),
  here("Data", "pooled_clusted_models.RDS")
)

# Group sample sizes (egos / ties) ------------------------------------------
cat("\n--- Group sample sizes, fully-adjusted analytic sample ---\n")
df_pooled_clean |>
  group_by(ego_rel) |>
  summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop") |>
  print()
