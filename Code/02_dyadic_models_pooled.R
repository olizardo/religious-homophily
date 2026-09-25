# Header ------------------------------------------------------------------
# Title: 02_dyadic_models_pooled
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Fit pooled longitudinal dyadic logistic regression models 
#          across Waves 3 to 8 of the NetHealth cohort, using robust 
#          clustered standard errors (clustered on ego) to account for 
#          non-independence of ties over time and within subjects.

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

# Degree Measures (Reviewer 1: activity/popularity confound) ---------------
# Computed per wave on the FULL nomination roster (before filtering to
# Student alters with known religion), since ego activity and alter
# popularity are properties of the underlying nomination behavior, not of
# the analytic subsample used for the homophily regression.
ego_degree_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  count(wave, egoid, name = "ego_out_degree")

alter_pop_all <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  count(wave, alterid, name = "alter_popularity")

# Prepare Pooled Long-Format Dyadic Dataset (Waves 3-8) -------------------
df_all <- df_netsurv |> 
  filter(wave %in% paste0("Wave", 3:8)) |> # Focus on waves with complete controls
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
  left_join(ego_degree_all, by = c("wave", "egoid")) |>
  left_join(alter_pop_all, by = c("wave", "alterid")) |>
  mutate(
    # Outcome: whether tie is homophilous
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    
    # Mathematical opportunity offset: log-odds of group proportion in that wave
    opportunity_offset = log(prop / (1 - prop)),
    
    # Alternative homophily dimensions
    same_gender = ifelse(gender_1 == altsex, 1, 0),
    same_race = case_when(
      race_1 == "White" & altwhite == TRUE ~ 1,
      race_1 == "African-American" & altblack == TRUE ~ 1,
      race_1 == "Asian-American" & altasian == TRUE ~ 1,
      race_1 == "Latino/a" & althisla == TRUE ~ 1,
      race_1 %in% c("White", "African-American", "Asian-American", "Latino/a") ~ 0,
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
    
    # Ego activity level (log out-degree) and alter popularity (log in-degree),
    # to separate homophily from degree-based confounds (Reviewer 1)
    log_ego_degree = log(ego_out_degree),
    log_alter_pop = log1p(alter_popularity),
    
    # Intimacy control (added 2026-09-24 for consistency with the Wave 3
    # specification in 02_dyadic_models.R; previously omitted here)
    close_num = case_when(
      close == "Distant" ~ 1,
      close == "LessThanClose" ~ 2,
      close == "MerelyClose" ~ 3,
      close == "EspeciallyClose" ~ 4,
      TRUE ~ NA_real_
    )
  )

# Filter to complete cases for modeling
df_pooled_clean <- df_pooled |>
  filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender), 
         !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(discuss_num),
         !is.na(log_ego_degree), !is.na(log_alter_pop), !is.na(close_num))

cat("Total pooled ties for regression (Waves 3-8):", nrow(df_pooled_clean), "\n")
cat("Number of unique egos:", n_distinct(df_pooled_clean$egoid), "\n\n")

# Fit Pooled Models -------------------------------------------------------

# Model 1: Baseline Opportunity-Adjusted Homophily (Pooled)
model1_pooled <- glm(same_religion ~ ego_rel, 
                     family = binomial, 
                     offset = opportunity_offset, 
                     data = df_pooled_clean)

# Model 2: Adding Demographic and Physical Foci Controls (Pooled)
model2_pooled <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num, 
                     family = binomial, 
                     offset = opportunity_offset, 
                     data = df_pooled_clean)

# Model 3: Adding Ego Activity (Out-Degree) and Alter Popularity (In-Degree)
# Reviewer 1 asked that homophily be separated from "main effect" activity
# differences by religion; these degree terms address that directly.
model3_pooled <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num + log_ego_degree + log_alter_pop, 
                     family = binomial, 
                     offset = opportunity_offset, 
                     data = df_pooled_clean)

# Compute Clustered Robust Standard Errors (Cluster on egoid) ------------
# This accounts for the nesting of multiple ties within egos, and multiple
# observations of the same egos across waves.

cat("========================================================================\n")
cat("POOLED MODEL 1: Baseline Opportunity-Adjusted Homophily (Clustered SE)\n")
cat("========================================================================\n")
m1_clustered <- coeftest(model1_pooled, vcov = vcovCL(model1_pooled, cluster = df_pooled_clean$egoid))
print(m1_clustered)

cat("\n========================================================================\n")
cat("POOLED MODEL 2: Structural and Demographic Controls (Clustered SE)\n")
cat("========================================================================\n")
m2_clustered <- coeftest(model2_pooled, vcov = vcovCL(model2_pooled, cluster = df_pooled_clean$egoid))
print(m2_clustered)

cat("\n========================================================================\n")
cat("POOLED MODEL 3: Adding Ego Activity / Alter Popularity (Clustered SE)\n")
cat("========================================================================\n")
m3_clustered <- coeftest(model3_pooled, vcov = vcovCL(model3_pooled, cluster = df_pooled_clean$egoid))
print(m3_clustered)

cat("\n--- Mean ego out-degree by religious group (pooled Waves 3-8) ---\n")
df_pooled_clean |>
  group_by(ego_rel) |>
  summarise(mean_ego_out_degree = mean(ego_out_degree, na.rm = TRUE), .groups = "drop") |>
  print()

# Save Clustered Tables to disk for easy retrieval -----------------------
# Save results to Rds
saveRDS(list(model1 = m1_clustered, model2 = m2_clustered, model3 = m3_clustered), here("Data", "pooled_clusted_models.RDS"))

# Group Sample Sizes (Egos / Ties) -------------------------------------------
# Reported alongside coefficients in Tabs/tbl-pooled-interaction-reg.tex so
# readers can judge the precision behind each group's coefficient (the Other
# Religion group has very few unique egos even pooled across all six waves).
cat("\n--- Group sample sizes, Model 2 (fully-adjusted) analytic sample ---\n")
df_pooled_clean |>
  group_by(ego_rel) |>
  summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop") |>
  print()
