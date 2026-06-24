# Header ------------------------------------------------------------------
# Title: 02_dyadic_models_interaction
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Fit dyadic logistic regression models interacting wave with 
#          religious group to test whether opportunity-adjusted minority 
#          homophily grows, decays, or remains stable over time (Waves 3-8), 
#          using robust standard errors clustered by egoid.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tidyr)
library(sandwich)
library(lmtest)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey(2-28-20).csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey(3-6-20).csv'))

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

# Wave-specific alter religious proportions (opportunity pool)
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
    # Outcome: whether tie is homophilous
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    
    # Mathematical opportunity offset
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
    
    # Continuous centered wave (Wave 3 = 0)
    # This centers interpretation of main effects directly at Wave 3 (Sophomore baseline)
    wave_num = as.numeric(gsub("Wave", "", wave)) - 3
  ) |>
  filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender), 
         !is.na(same_race), !is.na(roommates), !is.na(samedorm))

# Fit Interaction Model ---------------------------------------------------
cat("Fitting interaction model on", nrow(df_pooled), "ties across", n_distinct(df_pooled$egoid), "unique egos...\n")

model_interaction <- glm(
  same_religion ~ ego_rel * wave_num + same_gender + same_race + roommates + samedorm, 
  family = binomial, 
  offset = opportunity_offset, 
  data = df_pooled
)

# Compute clustered robust standard errors
clustered_results <- coeftest(model_interaction, vcov = vcovCL(model_interaction, cluster = df_pooled$egoid))

cat("\n========================================================================\n")
cat("INTERACTION MODEL: Religious Group * Centered Wave (Clustered SE)\n")
cat("========================================================================\n")
print(clustered_results)

# Save interaction results to disk
saveRDS(clustered_results, here("Data", "interaction_model_results.RDS"))
