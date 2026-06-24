# Header ------------------------------------------------------------------
# Title: 02_dyadic_models
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Fit dyadic (tie-level) logistic regression models predicting 
#          same-religion friendship ties, controlling for alternative 
#          homophilies (gender, race) and physical foci (roommates, dorms).

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey(2-28-20).csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey(3-6-20).csv'))

# Prepare Dyadic (Tie-level) Dataset for Wave 3 ----------------------------
df_w3 <- df_netsurv |> 
  filter(wave == "Wave3") |>
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

# Calculate Wave 3 overall alter religious proportions (opportunity pool)
alter_props <- df_w3 |>
  ungroup() |>
  count(alt_rel) |>
  mutate(prop = n / sum(n))

# Merge proportions and construct dyadic variables
df_w3_clean <- df_w3 |>
  left_join(alter_props |> select(alt_rel, prop), by = c("ego_rel" = "alt_rel")) |>
  mutate(
    # Outcome: whether tie is homophilous
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    
    # Mathematical opportunity offset: log-odds of group proportion
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
    )
  )

# Fit Nested Logistic Regression Models with Opportunity Offset -------------

# Model 1: Baseline Opportunity-Adjusted Homophily
model1 <- glm(same_religion ~ ego_rel, 
              family = binomial, 
              offset = opportunity_offset, 
              data = df_w3_clean)

# Model 2: Adding Demographic and Foci Controls (Race, Gender, Roommate, Dorm)
model2 <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm, 
              family = binomial, 
              offset = opportunity_offset, 
              data = df_w3_clean)

# Model 3: Adding Individual Religious Salience (Discussion Frequency)
model3 <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + discuss_num, 
              family = binomial, 
              offset = opportunity_offset, 
              data = df_w3_clean)

# Summarize and Save Models ------------------------------------------------

cat("\n======================================================\n")
cat("MODEL 1: Baseline Opportunity-Adjusted Homophily\n")
cat("======================================================\n")
print(summary(model1))

cat("\n======================================================\n")
cat("MODEL 2: Adding Structural Controls\n")
cat("======================================================\n")
print(summary(model2))

cat("\n======================================================\n")
cat("MODEL 3: Adding Religious Salience Proxy\n")
cat("======================================================\n")
print(summary(model3))

# Note on clustered standard errors:
# If the sandwich and lmtest packages are installed, robust standard errors 
# clustered by ego (egoid) can be calculated as follows:
# coeftest(model3, vcov = vcovCL(model3, cluster = df_w3_clean$egoid))
