# Header ------------------------------------------------------------------
# Title: 12_within_cohort_choice_model
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Status: EXPLORATORY. Not in the run order in AGENTS.md. Do not cite results
#         until the design is approved (AGENTS.md Section 9, item 12).
# Purpose: Within-cohort choice models (AGENTS.md Section 10.3A). The choice set is
#          the cohort roster, so no external opportunity baseline is needed.
#          Two conditional-logit designs on the same roster:
#          ES (ego-stratified): each responding ego-wave is a stratum; candidates
#              are all other roster members. Ego activity drops out. Alter
#              popularity must be modeled (alter-group effects, leave-own-out
#              in-degree).
#          AS (alter-stratified): each roster member in each wave is a stratum;
#              candidates are the responders in that wave. Alter popularity drops
#              out exactly; ego activity is modeled (log out-degree).
#          Religion is self-reported by both parties (BasicSurvey yourelig_1).
# Estimation: point estimates from the exact conditional logit (survival::clogit).
#          Ego-clustered SEs from the Breslow Cox form with strata and
#          cluster(egoid). clogit(method = "exact") does not support cluster(), and
#          dfbeta residuals are unavailable for the exact method. The Breslow
#          approximation degrades when a few candidates carry very large weights
#          (for example, reciprocity). The exact-vs-Breslow gap is reported per model.
# Sample:  Primary: Tier 1 and Tier 3 in-study egos with religion, gender, race,
#          and first-year residence hall known. Tier 2 egos were referred by Tier 1
#          students, so they are excluded from the primary models (Tier 2
#          sensitivity below). Waves 3-8. Family-nominated dyads are removed.
# Memory:  Each design has about one million rows. Models are fit one at a time,
#          and only coefficient vectors are kept.
# Output:  Data/within_cohort_choice_models.RDS (exploratory)

# Load libraries -----------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(survival)

# Two-way (Cameron-Gelbach-Miller) cluster-robust variance, for the plan's
# primary (M1) and popularity-adjusted (S1) ego/alter two-way SEs (plan
# WC-AS-v1, Section 8.1/8.3). Sourced into an isolated environment so this
# script's global environment stays uncluttered.
cv_env <- new.env()
sys.source(here("Code", "cluster_vcov.R"), envir = cv_env)

# Parameters ----------------------------------------------------------------
groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")
# Smoke test: WITHIN_COHORT_SMOKE=1 runs waves 3-4 and 150 roster egos (code-path check only)
smoke_test <- identical(Sys.getenv("WITHIN_COHORT_SMOKE"), "1")
waves <- if (smoke_test) 3:4 else 3:8
output_path <- if (smoke_test) {
  file.path(Sys.getenv("PA_SCRATCH_DIR", tempdir()), "within_cohort_smoke.RDS")
} else {
  # Plan WC-AS-v1, Section 9: the exploratory output (Data/within_cohort_choice_models.RDS,
  # md5 recorded in the plan's Section 0) is frozen and must not be overwritten once this
  # script implements two-way clustered SEs and the C1-C5 checks (plan Section 8.3).
  here("Data", paste0("within_cohort_preregistered_", format(Sys.Date(), "%Y%m%d"), ".RDS"))
}

# Load data -----------------------------------------------------------------
# Base-R reader (no readr): readr's vroom -> bit64 chain fails on Hoffman's R 4.2.2
# build. Empty strings are NA, matching readr's defaults for these columns.
read_survey <- function(file, keep) {
  out <- read.csv(here("Data", file), na.strings = c("", "NA"), check.names = FALSE,
                  stringsAsFactors = FALSE)[keep]
  # read.csv keeps the "True"/"False" codes of family as character; readr parses them as logical
  if ("family" %in% keep) out$family <- as.logical(out$family)
  out
}
basic <- read_survey("BasicSurvey.csv",
                     c("egoid", "Tier", "StudyStatus", "gender_1", "race_1",
                       "yourelig_1", "yourelig_7", "yourelig_8", "reshallyear1"))
nets <- read_survey("NetWorkSurvey.csv",
                    c("egoid", "alterid", "wave", "family", "altrelig")) |>
  mutate(wave_num = as.integer(sub("Wave", "", wave)))

nom_all <- nets |>
  filter(wave_num %in% waves) |>
  group_by(egoid, alterid, wave_num) |>
  summarise(family_nom = any(family), .groups = "drop")

responders_all <- nets |>
  filter(wave_num %in% waves) |>
  distinct(egoid, wave_num)

outdeg_all <- nets |>
  filter(wave_num %in% waves) |>
  count(egoid, wave_num, name = "outdeg")

# Functions -----------------------------------------------------------------
build_roster <- function(tiers) {
  roster <- basic |>
    filter(StudyStatus == "In Study", Tier %in% tiers) |>
    filter(as.character(yourelig_1) %in% groups,
           !is.na(gender_1), !is.na(race_1), !is.na(reshallyear1)) |>
    transmute(egoid, rel = as.character(yourelig_1), gender = gender_1,
              race = race_1, hall = reshallyear1)
  if (smoke_test) slice_head(roster, n = 150) else roster
}

# Invariants: every friend nomination among roster members appears once as an event,
# and no dyad pairs an ego with herself. Catches join errors such as the reciprocity bug.
check_dyads <- function(dyads, tiers) {
  expected_events <- nrow(roster_nominations(build_roster(tiers))$friend)
  stopifnot(
    "event count differs from roster friend nominations" = sum(dyads$y) == expected_events,
    "self-pairs present in dyad table" = !any(dyads$egoid == dyads$alt_egoid)
  )
  dyads
}

# Shared pieces: friend and family nominations within the roster, reverse nominations
roster_nominations <- function(roster) {
  ids <- roster$egoid
  list(
    friend = nom_all |> filter(!family_nom, egoid %in% ids, alterid %in% ids) |> select(egoid, alterid, wave_num),
    family = nom_all |> filter(family_nom, egoid %in% ids, alterid %in% ids) |> select(egoid, alterid, wave_num)
  )
}

# ES: one row per (responding ego, candidate roster alter, wave); stratum = ego-wave
build_dyads_ego <- function(tiers) {
  roster <- build_roster(tiers)
  noms <- roster_nominations(roster)
  responders <- responders_all |>
    semi_join(roster, by = "egoid") |>
    mutate(stratum = row_number())

  recip_key <- noms$friend |>
    rename(nominator = egoid, nominee = alterid) |>
    transmute(egoid = nominee, alt_egoid = nominator, wave_num, recip = 1L)
  resp_key <- responders |> transmute(alt_egoid = egoid, wave_num, alt_responded = 1L)
  indeg_key <- noms$friend |>
    transmute(alt_egoid = alterid, wave_num) |>
    count(alt_egoid, wave_num, name = "indeg")

  responders |>
    inner_join(roster, by = "egoid") |>
    cross_join(roster |> rename_with(\(x) paste0("alt_", x))) |>
    filter(egoid != alt_egoid) |>
    anti_join(noms$family |> rename(alt_egoid = alterid), by = c("egoid", "alt_egoid", "wave_num")) |>
    left_join(noms$friend |> rename(alt_egoid = alterid) |> mutate(y = 1L),
              by = c("egoid", "alt_egoid", "wave_num")) |>
    left_join(recip_key, by = c("egoid", "alt_egoid", "wave_num")) |>
    left_join(resp_key, by = c("alt_egoid", "wave_num")) |>
    left_join(indeg_key, by = c("alt_egoid", "wave_num")) |>
    mutate(
      y = coalesce(y, 0L),
      recip = coalesce(recip, 0L),
      recip_obs = as.integer(!is.na(alt_responded)),
      time1 = 1L,
      # In-degree from other responders in the wave (focal nomination removed)
      log_indeg = log1p(coalesce(indeg, 0L) - y),
      same_any = as.integer(rel == alt_rel),
      same_C = as.integer(rel == "Catholic" & alt_rel == "Catholic"),
      same_nonC = as.integer(rel != "Catholic" & same_any == 1L),
      same_NR = as.integer(rel == "No Religion" & alt_rel == "No Religion"),
      same_OR = as.integer(rel == "Other Religion" & alt_rel == "Other Religion"),
      same_P = as.integer(rel == "Protestant" & alt_rel == "Protestant"),
      alt_NR = as.integer(alt_rel == "No Religion"),
      alt_OR = as.integer(alt_rel == "Other Religion"),
      alt_P = as.integer(alt_rel == "Protestant"),
      same_gender = as.integer(gender == alt_gender),
      same_race = as.integer(race == alt_race),
      same_hall = as.integer(hall == alt_hall)
    ) |>
    select(egoid, alt_egoid, wave_num, stratum, y, time1, rel, alt_rel,
           recip, recip_obs, log_indeg, same_any, same_C, same_nonC, same_NR, same_OR, same_P,
           alt_NR, alt_OR, alt_P, same_gender, same_race, same_hall)
}

# AS: one row per (roster alter, responding ego, wave); stratum = alter-wave
build_dyads_alter <- function(tiers) {
  roster <- build_roster(tiers)
  noms <- roster_nominations(roster)
  responders <- responders_all |>
    semi_join(roster, by = "egoid") |>
    inner_join(roster, by = "egoid")
  targets <- roster |>
    rename(alt_egoid = egoid, alt_rel = rel, alt_gender = gender, alt_race = race, alt_hall = hall) |>
    tidyr::expand_grid(wave_num = waves)

  recip_key <- noms$friend |>
    rename(nominator = egoid, nominee = alterid) |>
    transmute(egoid = nominee, alt_egoid = nominator, wave_num, recip = 1L)
  resp_key <- responders_all |>
    semi_join(roster, by = "egoid") |>
    transmute(alt_egoid = egoid, wave_num, alt_responded = 1L)

  responders |>
    inner_join(targets, by = "wave_num", relationship = "many-to-many") |>
    filter(egoid != alt_egoid) |>
    anti_join(noms$family |> rename(alt_egoid = alterid), by = c("egoid", "alt_egoid", "wave_num")) |>
    left_join(noms$friend |> rename(alt_egoid = alterid) |> mutate(y = 1L),
              by = c("egoid", "alt_egoid", "wave_num")) |>
    left_join(recip_key, by = c("egoid", "alt_egoid", "wave_num")) |>
    left_join(resp_key, by = c("alt_egoid", "wave_num")) |>
    left_join(outdeg_all, by = c("egoid", "wave_num")) |>
    mutate(
      y = coalesce(y, 0L),
      recip = coalesce(recip, 0L),
      recip_obs = as.integer(!is.na(alt_responded)),
      log_outdeg = log(outdeg),
      time1 = 1L,
      stratum = as.integer(factor(paste(alt_egoid, wave_num))),
      same_any = as.integer(rel == alt_rel),
      same_C = as.integer(rel == "Catholic" & alt_rel == "Catholic"),
      same_nonC = as.integer(rel != "Catholic" & same_any == 1L),
      same_NR = as.integer(rel == "No Religion" & alt_rel == "No Religion"),
      same_OR = as.integer(rel == "Other Religion" & alt_rel == "Other Religion"),
      same_P = as.integer(rel == "Protestant" & alt_rel == "Protestant"),
      ego_NR = as.integer(rel == "No Religion"),
      ego_OR = as.integer(rel == "Other Religion"),
      ego_P = as.integer(rel == "Protestant"),
      same_gender = as.integer(gender == alt_gender),
      same_race = as.integer(race == alt_race),
      same_hall = as.integer(hall == alt_hall)
    ) |>
    select(egoid, alt_egoid, wave_num, stratum, y, time1, rel, alt_rel,
           recip, recip_obs, log_outdeg, same_any, same_C, same_nonC, same_NR, same_OR, same_P,
           ego_NR, ego_OR, ego_P, same_gender, same_race, same_hall)
}

# Fit one model; keep coefficient vectors, the robust vcov, and any fit warnings.
# two_way = TRUE additionally computes the ego/alter two-way cluster-robust
# vcov (plan WC-AS-v1, Section 5.2) from the Breslow fit's score residuals and
# naive variance, and the C2/C3 validity checks (Section 5.4). Only requested
# for M1 and S1 (plan Section 8.3); it is not computed for reciprocity models
# (C5: their SEs are never used in a claim).
fit_model <- function(rhs, data, two_way = FALSE) {
  warnings_seen <- character(0)
  record_warning <- function(w) {
    warnings_seen <<- c(warnings_seen, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
  ex <- withCallingHandlers(
    clogit(as.formula(paste("y ~", rhs, "+ strata(stratum)")), data = data),
    warning = record_warning)
  cl <- withCallingHandlers(
    coxph(as.formula(paste("Surv(time1, y) ~", rhs, "+ strata(stratum) + cluster(egoid)")),
          data = data, ties = "breslow"),
    warning = record_warning)
  out <- list(coef = coef(ex), cl_coef = coef(cl), V = vcov(cl),
              warnings = unique(warnings_seen))

  if (two_way) {
    # coxph does not attach term dimnames to $naive.var or to score residuals;
    # restore them from coef(cl) so downstream terms can be matched by name.
    term_names <- names(coef(cl))
    score <- as.matrix(residuals(cl, type = "score"))
    colnames(score) <- term_names
    naive_var <- cl$naive.var
    dimnames(naive_var) <- list(term_names, term_names)
    stopifnot(
      "score residuals and model data have mismatched row counts" = nrow(score) == nrow(data)
    )
    V_one <- cv_env$one_way_vcov(score, naive_var, data$egoid)
    V_two <- cv_env$two_way_vcov(score, naive_var, data$egoid, data$alt_egoid)
    out$V_two <- V_two
    out$two_way_se <- setNames(sqrt(diag(V_two)), colnames(V_two))
    # C2: the custom one-way (ego) vcov must reproduce coxph's own cluster(egoid) vcov.
    out$c2_max_diff <- max(abs(V_one - out$V))
    # C3: the two-way vcov must be (numerically) positive semidefinite.
    out$c3_min_eigenvalue <- cv_env$min_eigenvalue(V_two)
  }

  rm(ex, cl)
  invisible(gc(verbose = FALSE))
  out
}

tidy_fit <- function(res, design, label) {
  b <- res$coef
  se <- sqrt(diag(res$V))[names(b)]
  data.frame(design = design, model = label, term = names(b), estimate = b, cluster_se = se,
             OR = exp(b), lo95 = b - 1.96 * se, hi95 = b + 1.96 * se,
             p = 2 * pnorm(-abs(b / se)),
             exact_minus_breslow = b - res$cl_coef[names(b)], row.names = NULL)
}

# Contrast a minus b on the exact estimate with the clustered SE (aliased terms dropped).
# V defaults to the one-way (ego) clustered vcov; pass res$V_two for the two-way SE.
contrast <- function(res, design, label, a, b, V = NULL) {
  if (is.null(V)) V <- res$V
  nm <- intersect(names(res$coef)[!is.na(res$coef)], rownames(V))
  est_vec <- res$coef[nm]
  V <- V[nm, nm, drop = FALSE]
  L <- setNames(rep(0, length(nm)), nm)
  L[a] <- 1
  L[b] <- -1
  est <- sum(L * est_vec)
  se <- sqrt(as.numeric(t(L) %*% V %*% L))
  data.frame(design = design, model = label, contrast = paste(a, "minus", b),
             estimate = est, cluster_se = se, OR = exp(est),
             lo95 = est - 1.96 * se, hi95 = est + 1.96 * se,
             p = 2 * pnorm(-abs(est / se)), row.names = NULL)
}

# ES sample flow and diagnostics ------------------------------------------------
d_es <- build_dyads_ego(c("Tier 1", "Tier 3")) |> check_dyads(c("Tier 1", "Tier 3"))

cat("Choice set (Tier 1 and 3, in study, covariates known):",
    nrow(build_roster(c("Tier 1", "Tier 3"))), "egos\n")
cat("ES: responding ego-waves:", n_distinct(d_es$stratum), "; candidate dyads:", nrow(d_es),
    "; nominations:", sum(d_es$y), "\n")

descriptive <- d_es |>
  group_by(stratum) |>
  mutate(p_same_headcount = mean(same_any)) |>
  ungroup() |>
  filter(y == 1) |>
  group_by(ego_group = rel) |>
  summarise(n_nominations = n(),
            observed_same = mean(same_any),
            headcount_expected_same = mean(p_same_headcount),
            .groups = "drop")

shares <- d_es |>
  summarise(
    gender_candidates = mean(same_gender), gender_nominated = sum(y * same_gender) / sum(y),
    race_candidates = mean(same_race), race_nominated = sum(y * same_race) / sum(y),
    hall_candidates = mean(same_hall), hall_nominated = sum(y * same_hall) / sum(y)
  )

in_degree <- d_es |>
  filter(y == 1) |>
  count(alter_group = alt_rel, alter = alt_egoid, name = "received") |>
  group_by(alter_group) |>
  summarise(alters_with_nominations = n(), total_received = sum(received),
            top3_share = sum(head(sort(received, decreasing = TRUE), 3)) / sum(received),
            .groups = "drop")

roster_counts <- build_roster(c("Tier 1", "Tier 3")) |> count(rel, name = "roster_egos")

# Models ------------------------------------------------------------------------
rhs_alt <- "alt_NR + alt_OR + alt_P"
rhs_ctl <- "same_gender + same_race + same_hall"
rhs_pop <- "log_indeg + recip + recip_obs"

es_rhs <- list(
  ES_A_unadjusted = "same_C + same_nonC",
  ES_B_alter_groups = paste("same_C + same_nonC", rhs_alt, sep = " + "),
  ES_C_dyad_controls = paste("same_C + same_nonC", rhs_alt, rhs_ctl, sep = " + "),
  ES_D_primary = paste("same_C + same_nonC", rhs_alt, rhs_ctl, rhs_pop, sep = " + "),
  ES_D_no_recip = paste("same_C + same_nonC", rhs_alt, rhs_ctl, "log_indeg", sep = " + "),
  ES_E_no_alter_groups = paste("same_C + same_nonC", rhs_ctl, rhs_pop, sep = " + "),
  ES_E_no_recip = paste("same_C + same_nonC", rhs_ctl, "log_indeg", sep = " + "),
  ES_F_group_specific = paste("same_C + same_NR + same_OR + same_P", rhs_alt, rhs_ctl, rhs_pop, sep = " + ")
)

# ES_D_no_recip is plan WC-AS-v1's S1 (popularity-adjusted, no reciprocity; ego-
# stratified): the formula matches Section 4 exactly. Compute its two-way
# ego/alter SE while d_es is still in scope.
es_two_way <- setNames(rep(FALSE, length(es_rhs)), names(es_rhs))
es_two_way["ES_D_no_recip"] <- TRUE
es_results <- Map(fit_model, rhs = es_rhs, two_way = es_two_way, MoreArgs = list(data = d_es))
rm(d_es)
gc(verbose = FALSE)

d_es_t2 <- build_dyads_ego(c("Tier 1", "Tier 2", "Tier 3")) |>
  check_dyads(c("Tier 1", "Tier 2", "Tier 3"))
es_results$ES_G_with_tier2 <- fit_model(es_rhs$ES_D_primary, data = d_es_t2)
rm(d_es_t2)
gc(verbose = FALSE)

as_rhs <- list(
  AS_A_nonC = paste("same_C + same_nonC", "ego_NR + ego_OR + ego_P", "log_outdeg", rhs_ctl, sep = " + "),
  AS_B_recip = paste("same_C + same_nonC", "ego_NR + ego_OR + ego_P", "log_outdeg", rhs_ctl, "recip", sep = " + "),
  AS_C_group_specific = paste("same_C + same_NR + same_OR + same_P", "ego_NR + ego_OR + ego_P", "log_outdeg", rhs_ctl, sep = " + ")
)

d_as <- build_dyads_alter(c("Tier 1", "Tier 3")) |> check_dyads(c("Tier 1", "Tier 3"))
cat("AS: alter-wave strata:", n_distinct(d_as$stratum), "; candidate dyads:", nrow(d_as), "\n")
# AS_A_nonC is plan WC-AS-v1's M1 (primary, alter-stratified): the formula
# matches Section 4 exactly. Compute its two-way ego/alter SE while d_as is
# still in scope.
as_two_way <- setNames(rep(FALSE, length(as_rhs)), names(as_rhs))
as_two_way["AS_A_nonC"] <- TRUE
as_results <- Map(fit_model, rhs = as_rhs, two_way = as_two_way, MoreArgs = list(data = d_as))
rm(d_as)
gc(verbose = FALSE)

results <- c(es_results, as_results)
coef_table <- bind_rows(
  lapply(names(es_results), function(m) tidy_fit(es_results[[m]], "ES", m)),
  lapply(names(as_results), function(m) tidy_fit(as_results[[m]], "AS", m))
)

contrasts <- bind_rows(
  contrast(es_results$ES_D_primary, "ES", "ES_D_primary", "same_nonC", "same_C"),
  contrast(es_results$ES_E_no_alter_groups, "ES", "ES_E_no_alter_groups", "same_nonC", "same_C"),
  contrast(es_results$ES_G_with_tier2, "ES", "ES_G_with_tier2", "same_nonC", "same_C"),
  contrast(as_results$AS_A_nonC, "AS", "AS_A_nonC", "same_nonC", "same_C"),
  contrast(as_results$AS_B_recip, "AS", "AS_B_recip", "same_nonC", "same_C"),
  contrast(as_results$AS_C_group_specific, "AS", "AS_C_group_specific", "same_NR", "same_C"),
  contrast(as_results$AS_C_group_specific, "AS", "AS_C_group_specific", "same_OR", "same_C"),
  contrast(as_results$AS_C_group_specific, "AS", "AS_C_group_specific", "same_P", "same_C")
)

# --- Plan WC-AS-v1 (Section 8.3): two-way SEs and C1-C5 validity checks for M1 and S1 ---
# M1 = AS_A_nonC (primary, alter-stratified); S1 = ES_D_no_recip (popularity-adjusted,
# no reciprocity, ego-stratified). Both formulas match plan Section 4 exactly.
m1 <- as_results$AS_A_nonC
s1 <- es_results$ES_D_no_recip

# C1: |exact - Breslow| <= 0.05 for the plan's focal terms (Section 5.4).
focal_terms <- c("same_C", "same_nonC", "same_NR", "same_OR", "same_P", "alt_NR", "alt_OR", "alt_P")
c1_gap <- function(res, label) {
  b <- res$coef
  terms <- intersect(names(b), focal_terms)
  gap <- abs(b[terms] - res$cl_coef[terms])
  data.frame(model = label, term = terms, abs_exact_minus_breslow = gap,
             c1_pass = gap <= 0.05, row.names = NULL)
}
c1_table <- bind_rows(c1_gap(m1, "M1"), c1_gap(s1, "S1"))

# C2: the custom one-way (ego) vcov reproduces coxph's own cluster(egoid) vcov.
# C3: the two-way vcov is (numerically) positive semidefinite.
c2_c3_table <- data.frame(
  model = c("M1", "S1"),
  c2_max_diff_vs_coxph_cluster_vcov = c(m1$c2_max_diff, s1$c2_max_diff),
  c2_pass = c(m1$c2_max_diff, s1$c2_max_diff) <= 1e-8,
  c3_min_eigenvalue = c(m1$c3_min_eigenvalue, s1$c3_min_eigenvalue),
  c3_pass = c(m1$c3_min_eigenvalue, s1$c3_min_eigenvalue) >= -1e-10
)

# C4: the plan requires no clogit/coxph warnings specifically for M1; S1's are
# reported alongside for information but are not a pass/fail condition in the plan.
c4_table <- data.frame(
  model = c("M1", "S1"),
  n_warnings = c(length(m1$warnings), length(s1$warnings)),
  warnings = c(paste(m1$warnings, collapse = " | "), paste(s1$warnings, collapse = " | ")),
  c4_pass_required_for_m1 = c(length(m1$warnings) == 0, NA)
)

# C5: S3 (the ego-stratified reciprocity model) is never fit with two_way = TRUE in
# this script, so its standard errors are never computed here and cannot be reported
# as a claim -- satisfied by construction, not computed.

# Coefficient-level comparison of one-way (ego) vs two-way (ego/alter) SEs.
two_way_table <- bind_rows(
  data.frame(model = "M1", term = names(m1$two_way_se), estimate = m1$coef[names(m1$two_way_se)],
             one_way_se = sqrt(diag(m1$V))[names(m1$two_way_se)],
             two_way_se = m1$two_way_se, row.names = NULL),
  data.frame(model = "S1", term = names(s1$two_way_se), estimate = s1$coef[names(s1$two_way_se)],
             one_way_se = sqrt(diag(s1$V))[names(s1$two_way_se)],
             two_way_se = s1$two_way_se, row.names = NULL)
) |>
  mutate(lo95_two_way = estimate - 1.96 * two_way_se, hi95_two_way = estimate + 1.96 * two_way_se)

# Delta = same_nonC - same_C (the plan's primary contrast), with the two-way SE.
delta_two_way <- bind_rows(
  contrast(m1, "AS", "M1 (two-way)", "same_nonC", "same_C", V = m1$V_two),
  contrast(s1, "ES", "S1 (two-way)", "same_nonC", "same_C", V = s1$V_two)
)

# Measurement check: ego-reported vs self-reported alter religion (nominated ties) ---
self_tbl <- basic |>
  transmute(egoid, s1 = as.character(yourelig_1),
            s7 = as.character(yourelig_7), s8 = as.character(yourelig_8))

meas <- nets |>
  filter(wave_num %in% waves, !family, !is.na(altrelig)) |>
  distinct(egoid, alterid, wave_num, .keep_all = TRUE) |>
  left_join(self_tbl |> rename(alterid = egoid, a1 = s1, a7 = s7, a8 = s8), by = "alterid") |>
  left_join(self_tbl |> transmute(egoid, ego1 = s1), by = "egoid") |>
  filter(!is.na(a1), !is.na(ego1)) |>
  mutate(
    ego_report = case_when(altrelig == "NoReligion" ~ "No Religion",
                           altrelig == "OtherReligion" ~ "Other Religion",
                           TRUE ~ altrelig),
    alt_same_wave = case_when(wave_num == 7 ~ a7, wave_num == 8 ~ a8, TRUE ~ a1)
  )

measurement <- list(
  n_ties = nrow(meas),
  agreement_wave1_selfreport = mean(meas$ego_report == meas$a1),
  n_same_wave_w7_8 = sum(meas$wave_num %in% 7:8 & !is.na(meas$alt_same_wave)),
  agreement_same_wave_selfreport_w7_8 = mean(meas$ego_report[meas$wave_num %in% 7:8] ==
                                               meas$alt_same_wave[meas$wave_num %in% 7:8], na.rm = TRUE),
  confusion = table(self = meas$a1, ego_report = meas$ego_report),
  by_ego_group = meas |>
    filter(ego1 %in% groups) |>
    group_by(ego_group = ego1) |>
    summarise(n = n(),
              same_self_report = mean(a1 == ego1),
              same_ego_report = mean(ego_report == ego1),
              .groups = "drop")
)

# Output --------------------------------------------------------------------
saveRDS(
  list(coef_table = coef_table, contrasts = contrasts, descriptive = descriptive,
       shares = shares, in_degree = in_degree, roster_counts = roster_counts,
       measurement = measurement,
       fit_warnings = sapply(results, function(r) paste(r$warnings, collapse = " | ")),
       two_way_se = two_way_table, delta_two_way = delta_two_way,
       c1_table = c1_table, c2_c3_table = c2_c3_table, c4_table = c4_table),
  output_path
)

cat("\n--- Fit warnings by model (blank = none) ---\n")
print(sapply(results, function(r) paste(r$warnings, collapse = " | ")))
key_terms <- c("same_C", "same_nonC", "same_NR", "same_OR", "same_P",
               "alt_NR", "alt_OR", "alt_P", "ego_NR", "ego_OR", "ego_P",
               "log_indeg", "log_outdeg", "same_gender", "same_race", "same_hall",
               "recip", "recip_obs")
wide <- coef_table |>
  filter(term %in% key_terms) |>
  mutate(cell = sprintf("%.2f (%.2f)", estimate, cluster_se)) |>
  select(term, model, cell) |>
  pivot_wider(names_from = model, values_from = cell)
cat("\n--- Estimate (ego-clustered SE); exact conditional logit point estimates ---\n")
print(as.data.frame(wide), row.names = FALSE)
cat("\n--- Max |exact - Breslow| by model (SE validity check) ---\n")
print(coef_table |> group_by(model) |>
        summarise(max_abs_gap = max(abs(exact_minus_breslow), na.rm = TRUE), .groups = "drop") |>
        as.data.frame(), digits = 3, row.names = FALSE)
cat("\n--- Contrasts (same-religion log-odds) ---\n")
print(as.data.frame(contrasts), digits = 3, row.names = FALSE)
cat("\n--- M1/S1: one-way (ego) vs two-way (ego/alter) clustered SEs ---\n")
print(as.data.frame(two_way_table), digits = 3, row.names = FALSE)
cat("\n--- M1/S1: Delta = same_nonC - same_C, two-way clustered SE ---\n")
print(as.data.frame(delta_two_way), digits = 3, row.names = FALSE)
cat("\n--- C1 (|exact - Breslow| <= 0.05 for focal terms) ---\n")
print(c1_table, digits = 3, row.names = FALSE)
cat("\n--- C2 (one-way custom vcov vs coxph cluster vcov) / C3 (two-way vcov PSD) ---\n")
print(c2_c3_table, digits = 3, row.names = FALSE)
cat("\n--- C4 (fit warnings; plan requires none for M1) ---\n")
print(c4_table, row.names = FALSE)
cat("\n--- ES: observed vs headcount-expected same-religion share among nominations ---\n")
print(as.data.frame(descriptive), digits = 3, row.names = FALSE)
cat("\n--- ES: homophily shares, candidates vs nominations ---\n")
print(as.data.frame(shares), digits = 3, row.names = FALSE)
cat("\n--- ES: in-degree concentration by alter group ---\n")
print(as.data.frame(in_degree), digits = 3, row.names = FALSE)
cat("\n--- Measurement check: self-report vs ego-report ---\n")
print(measurement[c("n_ties", "agreement_wave1_selfreport", "n_same_wave_w7_8", "agreement_same_wave_selfreport_w7_8")])
print(as.data.frame.matrix(measurement$confusion))
print(as.data.frame(measurement$by_ego_group), digits = 3, row.names = FALSE)
