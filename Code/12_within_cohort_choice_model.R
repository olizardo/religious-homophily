# Header ------------------------------------------------------------------
# Title: 12_within_cohort_choice_model
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Status: Implements plan WC-AS-v1 (.posit/assistant/plans/2026-10-23-1510-preregistration-
#         alter-stratified.md), Sections 4-8.3: models M1, S1-S5, S10; two-way ego/alter SEs;
#         checks C1-C5; decision rules D1-D4; overlap audit. Not confirmatory (plan Section 0).
#         The exploratory version (job 15255017) is archived at
#         Archive/within_cohort_exploratory_2026-10-23/.
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
# Output:  Data/within_cohort_preregistered_<YYYYMMDD>.RDS (non-smoke runs only).
#          Smoke runs (WITHIN_COHORT_SMOKE=1) write to PA_SCRATCH_DIR, never to Data/.

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
  # Amendment 1 (plan Section 14): suffixed so the frozen run file is not overwritten.
  here("Data", paste0("within_cohort_preregistered_", format(Sys.Date(), "%Y%m%d"), "_amend1_race.RDS"))
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
    # Amendment 1 (plan Section 14): "Foreign Student" and "Other" race are one category
    transmute(egoid, rel = as.character(yourelig_1), gender = gender_1,
              race = if_else(race_1 %in% c("Foreign Student", "Other"), "Other", race_1),
              hall = reshallyear1)
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

# Plan WC-AS-v1 models (Section 4) -----------------------------------------------
tiers_main <- c("Tier 1", "Tier 3")
tiers_all <- c("Tier 1", "Tier 2", "Tier 3")

rhs_m1 <- "same_C + same_nonC + ego_NR + ego_OR + ego_P + log_outdeg + same_gender + same_race + same_hall"
rhs_s5 <- "same_C + same_NR + same_OR + same_P + ego_NR + ego_OR + ego_P + log_outdeg + same_gender + same_race + same_hall"
rhs_s1 <- "same_C + same_nonC + alt_NR + alt_OR + alt_P + same_gender + same_race + same_hall + log_indeg"
rhs_s3 <- paste(rhs_s1, "+ recip + recip_obs")
rhs_s4 <- "same_C + same_nonC + same_gender + same_race + same_hall + log_indeg"

focal_terms <- c("same_C", "same_nonC", "same_NR", "same_OR", "same_P", "alt_NR", "alt_OR", "alt_P")
delta <- c(same_nonC = 1, same_C = -1)

# Helpers -----------------------------------------------------------------------
sample_info <- function(d, tiers) {
  roster <- build_roster(tiers)
  list(
    tiers = paste(tiers, collapse = " + "),
    roster_egos = nrow(roster),
    roster_by_group = roster |> count(rel, name = "roster_egos"),
    risk_rows = nrow(d),
    strata = n_distinct(d$stratum),
    strata_with_event = n_distinct(d$stratum[d$y == 1]),
    choosers = n_distinct(d$egoid),
    targets = n_distinct(d$alt_egoid),
    nominations = sum(d$y),
    nominations_same_OR = sum(d$y * d$same_OR)
  )
}

# Plan Section 7: overlap audit, printed before any model in the block is read.
overlap_audit <- function(d, label) {
  nom <- filter(d, y == 1)
  pairs_risk <- distinct(d, egoid, alt_egoid)
  pairs_nom <- nom |> count(egoid, alt_egoid, name = "n_waves")
  targets <- unique(d$alt_egoid)
  choosers <- unique(d$egoid)
  nominated <- unique(nom$alt_egoid)
  repeated <- pairs_nom$n_waves >= 2
  data.frame(
    sample = label,
    item = c("Targets in risk set",
             "Targets receiving >= 1 nomination",
             "Choosers (responding roster egos)",
             "Choosers who are also targets (roster members)",
             "Choosers who also receive >= 1 nomination",
             "Ego-target pairs in risk set",
             "Pairs with >= 1 nomination",
             "Pairs nominated in >= 2 waves",
             "Dyad-periods (risk-set rows)",
             "Nominations (denominator: risk-set rows)",
             "Nominations on pairs nominated in >= 2 waves (denominator: nominations)"),
    count = c(length(targets), length(nominated), length(choosers),
              sum(choosers %in% targets), sum(choosers %in% nominated),
              nrow(pairs_risk), nrow(pairs_nom), sum(repeated),
              nrow(d), nrow(nom), sum(pairs_nom$n_waves[repeated])),
    denominator = c(length(targets), length(targets), length(choosers),
                    length(choosers), length(choosers),
                    nrow(pairs_risk), nrow(pairs_nom), nrow(pairs_nom),
                    nrow(d), nrow(d), nrow(nom)),
    row.names = NULL
  ) |>
    mutate(share = round(count / denominator, 4))
}

# Linear combination of coefficients with its variance; weights is a named vector.
# Returns NA if a weighted term is absent or aliased (e.g., no events in a smoke subset).
linear_ci <- function(b, V, weights) {
  nm <- names(weights)
  if (!all(nm %in% names(b)) || anyNA(b[nm])) return(setNames(rep(NA_real_, 5), c("estimate", "se", "lo95", "hi95", "p")))
  stopifnot(all(nm %in% rownames(V)))
  w <- as.numeric(weights)
  est <- sum(w * b[nm])
  se <- sqrt(as.numeric(t(w) %*% V[nm, nm, drop = FALSE] %*% w))
  c(estimate = est, se = se, lo95 = est - 1.96 * se, hi95 = est + 1.96 * se,
    p = 2 * pnorm(-abs(est / se)))
}

two_way_ci <- function(fit, weights) linear_ci(fit$coef, fit$V_two, weights)

ci_row <- function(model, label, weights, b, V, se_type) {
  r <- linear_ci(b, V, weights)
  data.frame(model = model, contrast = label, estimate = r[["estimate"]], se = r[["se"]],
             lo95 = r[["lo95"]], hi95 = r[["hi95"]], p = r[["p"]],
             OR = exp(r[["estimate"]]), se_type = se_type, row.names = NULL)
}

coef_rows <- function(res, design, model) {
  b <- res$coef
  nm <- names(b)
  se1 <- sqrt(diag(res$V))[nm]
  se2 <- if (is.null(res$V_two)) rep(NA_real_, length(nm)) else sqrt(diag(res$V_two))[nm]
  data.frame(design = design, model = model, term = nm, estimate = b,
             one_way_se = se1, two_way_se = se2,
             lo95_two_way = b - 1.96 * se2, hi95_two_way = b + 1.96 * se2,
             p_two_way = 2 * pnorm(-abs(b / se2)),
             exact_minus_breslow = b - res$cl_coef[nm],
             scale = "log-odds", row.names = NULL)
}

# S10: linear probability model with fixest (labelled robustness check, plan Section 4).
# Fixed effects: alter-wave (stratum) and chooser (egoid). Ego-level group indicators
# are absorbed by the chooser effect and are omitted. Clustering: egoid and alt_egoid.
run_s10 <- function(d) {
  if (!requireNamespace("fixest", quietly = TRUE)) {
    return(list(available = FALSE, note = "fixest not installed"))
  }
  fit <- tryCatch(
    fixest::feols(y ~ same_C + same_nonC + log_outdeg + same_gender + same_race + same_hall |
                    stratum + egoid, data = d, cluster = ~ egoid + alt_egoid),
    error = function(e) e)
  if (inherits(fit, "error")) return(list(available = FALSE, note = conditionMessage(fit)))
  list(available = TRUE, coef = coef(fit), V = vcov(fit),
       note = "LPM; FE alter-wave and chooser; two-way clustering; fixest default small-sample adjustment")
}

s10_rows <- function(s10) {
  b <- s10$coef
  se <- sqrt(diag(s10$V))[names(b)]
  data.frame(design = "AS", model = "S10", term = names(b), estimate = b,
             one_way_se = NA_real_, two_way_se = se,
             lo95_two_way = b - 1.96 * se, hi95_two_way = b + 1.96 * se,
             p_two_way = 2 * pnorm(-abs(b / se)), exact_minus_breslow = NA_real_,
             scale = "linear probability (not log-odds)", row.names = NULL)
}

# Run one design/roster block: build the risk set, check invariants, print the
# overlap audit before any model in the block is read, then fit the models.
run_block <- function(design, tiers, specs, label, s10 = FALSE) {
  build <- if (design == "AS") build_dyads_alter else build_dyads_ego
  d <- build(tiers) |> check_dyads(tiers)
  info <- sample_info(d, tiers)
  audit <- overlap_audit(d, label)
  cat("\n--- Overlap audit (plan Section 7):", label, "---\n")
  print(audit[, -1], row.names = FALSE)
  fits <- lapply(specs, function(sp) fit_model(rhs = sp$rhs, data = d, two_way = sp$two_way))
  s10_out <- if (s10) run_s10(d) else NULL
  rm(d)
  invisible(gc(verbose = FALSE))
  list(info = info, audit = audit, fits = fits, s10 = s10_out)
}

# Fits ----------------------------------------------------------------------------
blk_main_as <- run_block("AS", tiers_main, list(
  M1 = list(rhs = rhs_m1, two_way = TRUE),
  S5 = list(rhs = rhs_s5, two_way = TRUE)), "AS, Tier 1/3 (M1, S5, S10)", s10 = TRUE)

blk_main_es <- run_block("ES", tiers_main, list(
  S1 = list(rhs = rhs_s1, two_way = TRUE),
  S3 = list(rhs = rhs_s3, two_way = FALSE),
  S4 = list(rhs = rhs_s4, two_way = TRUE)), "ES, Tier 1/3 (S1, S3, S4)")

blk_all_as <- run_block("AS", tiers_all, list(
  S2 = list(rhs = rhs_m1, two_way = TRUE)), "AS, Tier 1/2/3 (S2)")

fits <- c(blk_main_as$fits, blk_main_es$fits, blk_all_as$fits)
s10 <- blk_main_as$s10
design_of <- c(M1 = "AS", S1 = "ES", S2 = "AS", S3 = "ES", S4 = "ES", S5 = "AS")

# Tables --------------------------------------------------------------------------
coef_table <- bind_rows(lapply(names(fits), function(m) coef_rows(fits[[m]], design_of[[m]], m)))
if (s10$available) coef_table <- bind_rows(coef_table, s10_rows(s10))

contrast_table <- bind_rows(
  lapply(setdiff(names(fits), "S5"), function(m) {
    se_type <- if (m == "S3") "one-way (point estimate only; not for claims, C5)" else "two-way"
    V <- if (m == "S3") fits[[m]]$V else fits[[m]]$V_two
    ci_row(m, "same_nonC minus same_C", delta, fits[[m]]$coef, V, se_type)
  }),
  if (s10$available) ci_row("S10", "same_nonC minus same_C", delta, s10$coef, s10$V,
                            "two-way (fixest LPM)") else NULL,
  ci_row("S5", "same_NR minus same_C", c(same_NR = 1, same_C = -1),
         fits$S5$coef, fits$S5$V_two, "two-way (descriptive)"),
  ci_row("S5", "same_OR minus same_C", c(same_OR = 1, same_C = -1),
         fits$S5$coef, fits$S5$V_two, "two-way (descriptive)"),
  ci_row("S5", "same_P minus same_C", c(same_P = 1, same_C = -1),
         fits$S5$coef, fits$S5$V_two, "two-way (descriptive)")
)

# C1-C4 (plan Section 5.4) for each fitted model. C5 is satisfied by construction (S3 never two-way).
checks <- bind_rows(lapply(names(fits), function(m) {
  r <- fits[[m]]
  terms <- intersect(names(r$coef), focal_terms)
  gap <- abs(r$coef[terms] - r$cl_coef[terms])
  two <- !is.null(r$V_two)
  data.frame(model = m,
             c1_max_gap = max(gap), c1_pass = all(gap <= 0.05),
             c2_max_diff = if (two) r$c2_max_diff else NA_real_,
             c2_pass = if (two) r$c2_max_diff <= 1e-8 else NA,
             c3_min_eigenvalue = if (two) r$c3_min_eigenvalue else NA_real_,
             c3_pass = if (two) r$c3_min_eigenvalue >= -1e-10 else NA,
             n_warnings = length(r$warnings),
             c4_pass = if (m == "M1") length(r$warnings) == 0 else NA,
             row.names = NULL)
}))

# A model's two-way SEs support claims only if its checks pass (plan Section 5.4-5.5).
# S3 is point-estimate only (C5).
claim_ok <- function(m) {
  if (m == "S3") return(FALSE)
  r <- checks[checks$model == m, ]
  focal_present <- all(c("same_C", "same_nonC") %in% names(fits[[m]]$coef)) &&
    !anyNA(fits[[m]]$coef[c("same_C", "same_nonC")])
  ok <- focal_present && r$c1_pass && isTRUE(r$c2_pass) && isTRUE(r$c3_pass)
  if (m == "M1") ok <- ok && isTRUE(r$c4_pass)
  ok
}

# Decision rules D1-D4 (plan Section 6) --------------------------------------------
m1_delta <- two_way_ci(fits$M1, delta)
s1_delta <- two_way_ci(fits$S1, delta)
m1_thc <- two_way_ci(fits$M1, c(same_C = 1))
m1_thn <- two_way_ci(fits$M1, c(same_nonC = 1))
s1_thc <- two_way_ci(fits$S1, c(same_C = 1))
s1_thn <- two_way_ci(fits$S1, c(same_nonC = 1))

fmt_ci <- function(ci) sprintf("%.2f (95%% CI %.2f to %.2f)", ci[["estimate"]], ci[["lo95"]], ci[["hi95"]])

d1_category <- function(ci, ok) {
  if (!ok) return("not reported (validity checks failed; plan Section 5.5, S9 bootstrap required)")
  if (ci[["lo95"]] > 0) return("non-Catholic in-group odds exceed Catholic in-group odds (MDH direction)")
  if (ci[["hi95"]] < 0) return("Catholic in-group odds exceed non-Catholic in-group odds (MEH direction)")
  "inconclusive"
}
d1_m1 <- d1_category(m1_delta, claim_ok("M1"))
d1_s1 <- d1_category(s1_delta, claim_ok("S1"))

d2 <- if (!claim_ok("M1")) {
  "not reported (validity checks failed)"
} else if (m1_thc[["lo95"]] > 0) {
  "Catholic in-group odds are elevated"
} else {
  paste("Catholic in-group interval reported:", fmt_ci(m1_thc))
}

d3 <- if (!claim_ok("M1")) {
  "not reported (validity checks failed)"
} else if (m1_thn[["lo95"]] <= 0 && m1_thn[["hi95"]] >= 0) {
  paste0("no detectable non-Catholic in-group excess: ", fmt_ci(m1_thn),
         "; upper bound as odds ratio ", sprintf("%.2f", exp(m1_thn[["hi95"]])))
} else {
  paste("interval excludes zero (not covered by D3; report the interval):", fmt_ci(m1_thn))
}

d4 <- claim_ok("M1") && claim_ok("S1") &&
  sign(m1_thc[["estimate"]]) == sign(s1_thc[["estimate"]]) &&
  sign(m1_thn[["estimate"]]) == sign(s1_thn[["estimate"]]) &&
  d1_m1 == d1_s1

or_row <- blk_main_as$info$roster_by_group
or_egos <- or_row$roster_egos[or_row$rel == "Other Religion"]
decisions <- data.frame(
  rule = c("D1 (M1, primary)", "D1 applied to S1 (for D4 only)", "D2 (M1, Catholic in-group)",
           "D3 (M1, non-Catholic in-group)", "D4 (S1 agrees with M1)", "D7 (Other Religion sample)"),
  result = c(d1_m1, d1_s1, d2, d3,
             if (d4) "S1 agrees with M1" else "S1 does not agree with M1",
             sprintf("%d roster egos; %d same-religion nominations (AS, Tier 1/3)",
                     or_egos, blk_main_as$info$nominations_same_OR)),
  row.names = NULL
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

# Output --------------------------------------------------------------------------
saveRDS(
  list(
    plan = "WC-AS-v1",
    smoke_test = smoke_test,
    run_time = Sys.time(),
    R_version = R.version.string,
    survival_version = as.character(packageVersion("survival")),
    fixest_version = if (requireNamespace("fixest", quietly = TRUE)) as.character(packageVersion("fixest")) else NA,
    samples = list(AS_tiers13 = blk_main_as$info, ES_tiers13 = blk_main_es$info,
                   AS_tiers123 = blk_all_as$info),
    audits = bind_rows(blk_main_as$audit, blk_main_es$audit, blk_all_as$audit),
    models = lapply(fits, function(r) r[c("coef", "cl_coef", "V", "V_two", "two_way_se",
                                          "c2_max_diff", "c3_min_eigenvalue", "warnings")]),
    s10 = s10,
    coef_table = coef_table,
    contrasts = contrast_table,
    checks = checks,
    decisions = decisions,
    measurement = measurement
  ),
  output_path
)

cat("\nOutput written to:", output_path, "\n")
cat("\n--- Fit warnings by model (blank = none) ---\n")
print(sapply(fits, function(r) paste(r$warnings, collapse = " | ")))
key_terms <- c("same_C", "same_nonC", "same_NR", "same_OR", "same_P",
               "alt_NR", "alt_OR", "alt_P", "ego_NR", "ego_OR", "ego_P",
               "log_indeg", "log_outdeg", "same_gender", "same_race", "same_hall",
               "recip", "recip_obs")
cat("\n--- Estimates: log-odds (exact conditional logit); SE = two-way (ego/alter) where computed ---\n")
print(coef_table |> filter(term %in% key_terms) |>
        mutate(cell = sprintf("%.2f (%.2f)", estimate, one_way_se), two = sprintf("%.2f (%.2f)", estimate, two_way_se)) |>
        select(model, term, one_way = cell, two_way = two) |>
        as.data.frame(), row.names = FALSE)
cat("\n--- Contrasts ---\n")
print(as.data.frame(contrast_table), digits = 3, row.names = FALSE)
cat("\n--- Checks C1-C4 (C5 by construction) ---\n")
print(as.data.frame(checks), digits = 3, row.names = FALSE)
cat("\n--- Decisions D1-D7 ---\n")
print(decisions, right = FALSE, row.names = FALSE)
cat("\n--- Measurement check: self-report vs ego-report ---\n")
print(measurement[c("n_ties", "agreement_wave1_selfreport", "n_same_wave_w7_8", "agreement_same_wave_selfreport_w7_8")])
print(as.data.frame.matrix(measurement$confusion))
print(as.data.frame(measurement$by_ego_group), digits = 3, row.names = FALSE)
