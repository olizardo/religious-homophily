# Header ------------------------------------------------------------------
# Title: 02_dyadic_models
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Fit dyadic (tie-level) logistic regression models predicting 
#          same-religion friendship ties, controlling for alternative 
#          homophilies (gender, race), physical foci (roommates, dorms), and
#          (Model 4, added 2026-09-24 per Reviewer 1) ego activity level and
#          alter popularity, to separate homophily from degree-based
#          confounds.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Degree Measures (Reviewer 1: activity/popularity confound) ---------------
# Computed on the FULL Wave 3 nomination roster (before filtering to Student
# alters with known religion), since ego activity and alter popularity are
# properties of the underlying nomination behavior, not of the analytic
# subsample used for the homophily regression.
ego_degree_w3 <- df_netsurv |>
  filter(wave == "Wave3") |>
  count(egoid, name = "ego_out_degree")

alter_pop_w3 <- df_netsurv |>
  filter(wave == "Wave3") |>
  count(alterid, name = "alter_popularity")

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
  left_join(ego_degree_w3, by = "egoid") |>
  left_join(alter_pop_w3, by = "alterid") |>
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
    
    # Intimacy controls
    close_num = case_when(
      close == "Distant" ~ 1,
      close == "LessThanClose" ~ 2,
      close == "MerelyClose" ~ 3,
      close == "EspeciallyClose" ~ 4,
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
    log_alter_pop = log1p(alter_popularity)
  )

# Fit Nested Logistic Regression Models with Opportunity Offset -------------

# Model 1: Baseline Opportunity-Adjusted Homophily
model1 <- glm(same_religion ~ ego_rel, 
              family = binomial, 
              offset = opportunity_offset, 
              data = df_w3_clean)

# Model 2: Adding Demographic and Foci Controls (Race, Gender, Roommate, Dorm)
model2 <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num, 
              family = binomial, 
              offset = opportunity_offset, 
              data = df_w3_clean)

# Model 3: Adding Individual Religious Salience (Discussion Frequency)
model3 <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num, 
              family = binomial, 
              offset = opportunity_offset, 
              data = df_w3_clean)

# Model 4: Adding Ego Activity (Out-Degree) and Alter Popularity (In-Degree)
# Reviewer 1 asked that homophily be separated from "main effect" activity
# differences by religion; these degree terms address that directly.
model4 <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num + discuss_num + log_ego_degree + log_alter_pop, 
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

cat("\n======================================================\n")
cat("MODEL 4: Adding Ego Activity / Alter Popularity (Degree)\n")
cat("======================================================\n")
print(summary(model4))

cat("\n--- Ego out-degree and alter popularity by religious group (Wave 3) ---\n")
df_w3_clean |>
  group_by(ego_rel) |>
  summarise(mean_ego_out_degree = mean(ego_out_degree, na.rm = TRUE), .groups = "drop") |>
  print()

# Note on clustered standard errors:
# If the sandwich and lmtest packages are installed, robust standard errors 
# clustered by ego (egoid) can be calculated as follows:
# coeftest(model3, vcov = vcovCL(model3, cluster = df_w3_clean$egoid))

# Group Sample Sizes (Egos / Ties) by Model ---------------------------------
# Reported alongside coefficients in Tabs/tbl-wave3-reg.tex so readers can
# judge the precision behind each group's coefficient (the Other Religion
# group in particular has very few unique egos).
report_group_n <- function(dat, label) {
  cat("\n---", label, "---\n")
  dat |>
    group_by(ego_rel) |>
    summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop") |>
    print()
}

m1_sample <- df_w3_clean |> filter(!is.na(same_religion), !is.na(opportunity_offset))
m2_sample <- df_w3_clean |> filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender),
                                    !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(close_num))
m3_sample <- df_w3_clean |> filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender),
                                    !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(close_num),
                                    !is.na(discuss_num))
m4_sample <- df_w3_clean |> filter(!is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender),
                                    !is.na(same_race), !is.na(roommates), !is.na(samedorm), !is.na(close_num),
                                    !is.na(discuss_num), !is.na(log_ego_degree), !is.na(log_alter_pop))

report_group_n(m1_sample, "Model 1 sample sizes")
report_group_n(m2_sample, "Model 2 sample sizes")
report_group_n(m3_sample, "Model 3 sample sizes")
report_group_n(m4_sample, "Model 4 sample sizes")
