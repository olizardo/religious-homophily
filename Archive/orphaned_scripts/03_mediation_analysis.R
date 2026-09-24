# Header ------------------------------------------------------------------
# Title: 03_mediation_analysis
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Purpose: Formal causal mediation analysis testing whether physical foci
#          (same-dorm co-residence, roommate status) and demographic
#          sorting (race homophily) mediate the association between being
#          a "No Religion" ego (vs. Catholic) and forming a same-religion
#          tie at Wave 3.
#
# Background: an earlier paper draft cited Average Causal Mediation Effect
# (ACME) estimates from a `mediation`-package analysis (e.g., p = 0.32 for
# same-dorm co-residence, p = 0.16 for race homophily), used to argue that
# the No Religion coefficient's stability across nested logistic models was
# a genuine, unmediated association rather than an artifact of structural
# sorting. That claim was removed from the manuscript on 2026-09-24 because
# no script producing those numbers could be found anywhere in git history
# (see AGENTS.md, Section 6). This script rebuilds that analysis from
# scratch, saved and documented, so results are reproducible going forward.
#
# NOTE ON SCOPE: as of 2026-09-24, the corrected Code/02_dyadic_models.R
# shows the No Religion coefficient is NOT statistically significant in
# Wave 3 Models 2-4 (once tie-level structural controls are added) -- see
# Tabs/tbl-wave3-reg.tex. A mediation analysis presumes there is a total
# effect worth decomposing; because the Wave 3 total effect for No Religion
# vs. Catholic is only marginal, ACME/ADE estimates here should be read as
# a diagnostic of *whether* structural sorting could plausibly explain a
# same-religion-tie disparity between these two groups, not as evidence
# that mediates a well-established significant effect. We report both the
# total effect and its decomposition so this caveat is transparent.
#
# METHOD: the `mediation` package (Imai, Keele, and Tingley 2010) requires
# a binary treatment. We therefore restrict the analytic sample to the
# Catholic/No Religion comparison (dropping Protestant and Other Religion
# egos), fit a mediator model (mediator ~ treatment + controls) and an
# outcome model (same_religion ~ treatment + mediator + controls, with the
# opportunity offset), and simulate the ACME/ADE with mediate(). We repeat
# this separately for three candidate mediators considered "physical or
# demographic foci" in the manuscript: same-dorm co-residence, roommate
# status, and race homophily. As in Code/02_dyadic_models.R's (unclustered)
# Wave 3 models, standard errors here do not adjust for the clustering of
# multiple ties within the same ego; this is a known limitation shared with
# the corresponding cross-sectional regression table.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(mediation)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Degree Measures (computed identically to Code/02_dyadic_models.R) --------
ego_degree_w3 <- df_netsurv |>
  filter(wave == "Wave3") |>
  count(egoid, name = "ego_out_degree")

alter_pop_w3 <- df_netsurv |>
  filter(wave == "Wave3") |>
  count(alterid, name = "alter_popularity")

# Prepare Dyadic (Tie-level) Dataset for Wave 3 -----------------------------
# This block is intentionally identical to Code/02_dyadic_models.R so that
# the mediation analysis operates on the same analytic sample and variable
# definitions as the regression table it is meant to complement.
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

alter_props <- df_w3 |>
  ungroup() |>
  count(alt_rel) |>
  mutate(prop = n / sum(n))

df_w3_clean <- df_w3 |>
  left_join(alter_props |> dplyr::select(alt_rel, prop), by = c("ego_rel" = "alt_rel")) |>
  left_join(ego_degree_w3, by = "egoid") |>
  left_join(alter_pop_w3, by = "alterid") |>
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
    close_num = case_when(
      close == "Distant" ~ 1,
      close == "LessThanClose" ~ 2,
      close == "MerelyClose" ~ 3,
      close == "EspeciallyClose" ~ 4,
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
    roommates_num = as.numeric(roommates),
    samedorm_num = as.numeric(samedorm),
    log_ego_degree = log(ego_out_degree),
    log_alter_pop = log1p(alter_popularity)
  )

# Restrict to the Catholic/No Religion Comparison ---------------------------
# The `mediation` package requires a binary treatment; Protestant and Other
# Religion egos are dropped from this specific analysis (they are retained,
# as always, in Code/02_dyadic_models.R's multi-group regressions).
df_med <- df_w3_clean |>
  filter(ego_rel %in% c("Catholic", "No Religion")) |>
  mutate(treat_no_religion = ifelse(ego_rel == "No Religion", 1, 0)) |>
  filter(
    !is.na(same_religion), !is.na(opportunity_offset), !is.na(same_gender),
    !is.na(same_race), !is.na(roommates_num), !is.na(samedorm_num),
    !is.na(close_num), !is.na(discuss_num),
    !is.na(log_ego_degree), !is.na(log_alter_pop)
  )

cat("Mediation analytic sample (Catholic vs. No Religion, Wave 3):\n")
df_med |>
  group_by(ego_rel) |>
  summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop") |>
  print()

# Total Effect (No Mediator) -------------------------------------------------
# This is the Wave 3, two-group analogue of Model 3 in Table tab:wave3-reg,
# i.e., the effect we are attempting to decompose below.
total_effect_model <- glm(
  same_religion ~ treat_no_religion + same_gender + close_num + discuss_num + log_ego_degree + log_alter_pop,
  family = binomial,
  offset = opportunity_offset,
  data = df_med
)
cat("\n======================================================\n")
cat("TOTAL EFFECT: No Religion vs. Catholic (Wave 3, two-group sample)\n")
cat("======================================================\n")
print(summary(total_effect_model))

# Mediation Analysis Helper Function -----------------------------------------
# Fits a mediator model and an outcome model that both control for the same
# set of individual/tie covariates (gender homophily, closeness, salience,
# ego activity, alter popularity), then simulates ACME/ADE via mediate().
# The other two candidate mediators are deliberately NOT included as
# controls in a given model, since including a variable that may itself be
# affected by treatment as a "control" for a parallel mediator risks
# post-treatment bias.
run_mediation <- function(mediator_name, mediator_family = binomial, sims = 2000, seed) {
  set.seed(seed)
  
  covariates <- "same_gender + close_num + discuss_num + log_ego_degree + log_alter_pop"
  
  mediator_formula <- as.formula(paste(mediator_name, "~ treat_no_religion +", covariates))
  outcome_formula <- as.formula(paste("same_religion ~ treat_no_religion +", mediator_name, "+", covariates))
  
  mediator_model <- glm(mediator_formula, family = mediator_family, data = df_med)
  outcome_model <- glm(outcome_formula, family = binomial, offset = opportunity_offset, data = df_med)
  
  mediate(
    mediator_model, outcome_model,
    treat = "treat_no_religion", mediator = mediator_name,
    sims = sims, robustSE = FALSE
  )
}

# Run Mediation Models for Each Candidate Mediator ---------------------------
# Seeds are distinct random integers (not sequential/special values) so
# each quasi-Bayesian simulation is independently reproducible.
med_samedorm <- run_mediation("samedorm_num", seed = 8264)
med_roommates <- run_mediation("roommates_num", seed = 3947)
med_samerace <- run_mediation("same_race", seed = 6021)

cat("\n======================================================\n")
cat("MEDIATION: Same-Dorm Co-Residence\n")
cat("======================================================\n")
print(summary(med_samedorm))

cat("\n======================================================\n")
cat("MEDIATION: Roommate Status\n")
cat("======================================================\n")
print(summary(med_roommates))

cat("\n======================================================\n")
cat("MEDIATION: Race Homophily\n")
cat("======================================================\n")
print(summary(med_samerace))

# Save Results ----------------------------------------------------------
saveRDS(
  list(
    sample_sizes = df_med |> group_by(ego_rel) |> summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop"),
    total_effect_model = total_effect_model,
    med_samedorm = med_samedorm,
    med_roommates = med_roommates,
    med_samerace = med_samerace
  ),
  here("Data", "mediation_results.RDS")
)

cat("\nSaved mediation results to Data/mediation_results.RDS\n")
