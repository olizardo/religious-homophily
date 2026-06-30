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

# Prepare Pooled Long-Format Dyadic Dataset (Waves 3-8) -------------------
df_all <- df_netsurv |> 
  filter(wave %in% paste0("Wave", 3:8)) |> # Focus on waves with complete controls
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
    )
  )

# Filter to complete cases for modeling
df_pooled_clean <- df_pooled |>
  filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender), 
         !is.na(same_race), !is.na(roommates), !is.na(samedorm))

cat("Total pooled ties for regression (Waves 3-8):", nrow(df_pooled_clean), "\n")
cat("Number of unique egos:", n_distinct(df_pooled_clean$egoid), "\n\n")

# Fit Pooled Models -------------------------------------------------------

# Model 1: Baseline Opportunity-Adjusted Homophily (Pooled)
model1_pooled <- glm(same_religion ~ ego_rel, 
                     family = binomial, 
                     offset = opportunity_offset, 
                     data = df_pooled_clean)

# Model 2: Adding Demographic and Physical Foci Controls (Pooled)
model2_pooled <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm, 
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

# Save Clustered Tables to disk for easy retrieval -----------------------
# Save results to Rds
saveRDS(list(model1 = m1_clustered, model2 = m2_clustered), here("Data", "pooled_clusted_models.RDS"))
