# Header ------------------------------------------------------------------
# Title: 02_dyadic_models_close
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Fit dyadic logistic regression models restricting the pooled 
#          longitudinal dataset strictly to intimate (Especially Close) 
#          friendships, testing if boundary distinctiveness and temporal 
#          stability are amplified for high-intensity social ties.

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

# Prepare Pooled Dataset (Waves 3-8) --------------------------------------
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

# Merge proportions and construct centered wave variable
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
    wave_num = as.numeric(gsub("Wave", "", wave)) - 3
  ) |>
  filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender), 
         !is.na(same_race), !is.na(roommates), !is.na(samedorm))

# Filter strictly to "EspeciallyClose" (intimate) ties --------------------
df_pooled_intimate <- df_pooled |>
  filter(close == "EspeciallyClose")

cat("Fitting interaction model on intimate ties (N =", nrow(df_pooled_intimate), ")\n")

# Fit model
model_intimate <- glm(
  same_religion ~ ego_rel * wave_num + same_gender + same_race + roommates + samedorm, 
  family = binomial, 
  offset = opportunity_offset, 
  data = df_pooled_intimate
)

# Compute clustered robust standard errors (Cluster on egoid)
clustered_intimate <- coeftest(model_intimate, vcov = vcovCL(model_intimate, cluster = df_pooled_intimate$egoid))

cat("\n========================================================================\n")
cat("INTIMATE TIES MODEL (Especially Close): Group * Centered Wave (Clustered SE)\n")
cat("========================================================================\n")
print(clustered_intimate)

# Save intimate model results to disk
saveRDS(clustered_intimate, here("Data", "intimate_model_results.RDS"))
