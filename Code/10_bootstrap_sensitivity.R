# Header ------------------------------------------------------------------
# Title: 10_bootstrap_sensitivity
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Revised: 2026-10-23 - every quantity is computed under two opportunity baselines:
#          the ego-cohort composition (primary) and the nominated-alter pool
#          (sensitivity). The header note on "directly comparable" excess rates is
#          withdrawn: an excess probability depends on the group's baseline share
#          by construction, so Panels A-B are descriptive. Log-odds contrasts
#          (Panels C-D) are the basis for group comparisons.
# Purpose: Ego-level cluster bootstrap of the excess in-group tie rate and
#          Wald tests of pairwise equality of the pooled log-odds coefficients.
#
#          Bootstrap: resample egos WITH REPLACEMENT, separately within each group,
#          so each resampled ego's ties (all waves) move together. Statistic per
#          group = observed same-religion rate minus the mean opportunity baseline.
#          Pairwise CIs use independent group bootstraps.
#
#          Wald: pairwise contrasts L'b with the ego-clustered vcov from the
#          Code/02_dyadic_models_pooled.R fits (Model 1 and Model 3, both baselines).
#          Manual contrasts are used because car::linearHypothesis() cannot parse
#          level names containing spaces.

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(sandwich)
library(lmtest)

groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")
n_reps <- 2000

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Prepare pooled long-format dyadic dataset (Waves 3-8) -------------------
# Baseline sample (no covariate filtering), as in the committed version.
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

# Baselines (same definitions as Code/02_dyadic_models_pooled.R)
cohort_props <- df_basicsurv |>
  mutate(ego_rel = as.character(yourelig_1)) |>
  filter(ego_rel %in% groups) |>
  count(ego_rel, name = "n_cohort") |>
  mutate(prop_cohort = n_cohort / sum(n_cohort)) |>
  select(ego_rel, prop_cohort)

wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop_pool = n / sum(n)) |>
  ungroup()

df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop_pool), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  left_join(cohort_props, by = "ego_rel") |>
  mutate(same_religion = ifelse(ego_rel == alt_rel, 1, 0)) |>
  select(egoid, ego_rel, same_religion, prop_pool, prop_cohort)

cat("Total pooled ties for bootstrap (Waves 3-8):", nrow(df_pooled), "\n")
cat("Total unique egos who contribute ties:", n_distinct(df_pooled$egoid), "\n\n")

baselines <- list(
  pool = list(prop_col = "prop_pool", seed = 6284),
  cohort = list(prop_col = "prop_cohort", seed = 6285)
)

# Bootstrap of the excess rate under one baseline -----------------------------
run_excess_bootstrap <- function(prop_col, seed) {
  set.seed(seed)

  observed_summary <- df_pooled |>
    group_by(ego_rel) |>
    summarise(
      n_egos = n_distinct(egoid),
      n_ties = n(),
      observed_rate = mean(same_religion),
      baseline_rate = mean(.data[[prop_col]]),
      excess = observed_rate - baseline_rate,
      .groups = "drop"
    )

  boot_excess <- function(g) {
    dat_g <- df_pooled |> filter(ego_rel == g)
    egos_g <- unique(dat_g$egoid)
    same_by_ego <- split(dat_g$same_religion, dat_g$egoid)
    prop_by_ego <- split(dat_g[[prop_col]], dat_g$egoid)

    replicate(n_reps, {
      boot_ids <- sample(egos_g, length(egos_g), replace = TRUE)
      same_vec <- unlist(same_by_ego[as.character(boot_ids)], use.names = FALSE)
      prop_vec <- unlist(prop_by_ego[as.character(boot_ids)], use.names = FALSE)
      mean(same_vec) - mean(prop_vec)
    })
  }

  boot_results <- lapply(groups, boot_excess)
  names(boot_results) <- groups

  group_ci <- bind_rows(lapply(groups, function(g) {
    b <- boot_results[[g]]
    tibble::tibble(
      ego_rel = g,
      boot_mean_excess = mean(b),
      ci_lo = quantile(b, 0.025),
      ci_hi = quantile(b, 0.975)
    )
  }))

  pairs <- combn(groups, 2, simplify = FALSE)
  pairwise_ci <- bind_rows(lapply(pairs, function(p) {
    diff_vec <- boot_results[[p[1]]] - boot_results[[p[2]]]
    tibble::tibble(
      group1 = p[1],
      group2 = p[2],
      mean_diff = mean(diff_vec),
      ci_lo = quantile(diff_vec, 0.025),
      ci_hi = quantile(diff_vec, 0.975),
      excludes_zero = (quantile(diff_vec, 0.025) > 0) | (quantile(diff_vec, 0.975) < 0)
    )
  }))

  list(
    observed_summary = observed_summary,
    boot_results = boot_results,
    group_ci = group_ci,
    pairwise_ci = pairwise_ci
  )
}

excess <- lapply(baselines, function(b) run_excess_bootstrap(b$prop_col, b$seed))

for (nm in names(excess)) {
  cat("\n=== Excess in-group tie rate, baseline:", nm, "===\n")
  print(excess[[nm]]$observed_summary)
  print(excess[[nm]]$group_ci)
  print(excess[[nm]]$pairwise_ci, n = Inf)
}

# Wald tests ------------------------------------------------------------------
# A "Catholic vs. X" contrast reduces to testing X's coefficient against zero
# (Catholic is the reference level). The estimate is Catholic minus X.
wald_contrast <- function(model, vcov_mat, term1, term2 = NULL) {
  b <- coef(model)
  L <- setNames(rep(0, length(b)), names(b))
  L[term1] <- if (is.null(term2)) -1 else 1
  if (!is.null(term2)) L[term2] <- -1
  est <- sum(L * b)
  se <- sqrt(as.numeric(t(L) %*% vcov_mat %*% L))
  chisq <- (est / se)^2
  tibble::tibble(
    group1 = if (is.null(term2)) "Catholic" else sub("^ego_rel", "", term1),
    group2 = if (is.null(term2)) sub("^ego_rel", "", term1) else sub("^ego_rel", "", term2),
    log_odds_diff = est,
    se = se,
    chisq = chisq,
    p_value = pchisq(chisq, df = 1, lower.tail = FALSE)
  )
}

all_group_pairs <- list(
  list(term1 = "ego_relNo Religion", term2 = NULL),
  list(term1 = "ego_relOther Religion", term2 = NULL),
  list(term1 = "ego_relProtestant", term2 = NULL),
  list(term1 = "ego_relNo Religion", term2 = "ego_relOther Religion"),
  list(term1 = "ego_relNo Religion", term2 = "ego_relProtestant"),
  list(term1 = "ego_relOther Religion", term2 = "ego_relProtestant")
)

# Source Code 02 into its own environment (not the global environment)
pooled_env <- new.env()
source(here("Code", "02_dyadic_models_pooled.R"), local = pooled_env)

wald_for <- function(model_name) {
  model <- pooled_env[[model_name]]
  vc <- vcovCL(model, cluster = pooled_env$df_pooled_clean$egoid)
  res <- bind_rows(lapply(all_group_pairs, function(p) {
    wald_contrast(model, vc, p$term1, p$term2)
  }))
  res$p_holm <- p.adjust(res$p_value, method = "holm")
  res
}

wald <- list(
  cohort_m1 = wald_for("model1_pooled"),
  cohort_m3 = wald_for("model3_pooled"),
  pool_m1 = wald_for("model1_pool"),
  pool_m3 = wald_for("model3_pool")
)

for (nm in names(wald)) {
  cat("\n--- Wald tests:", nm, "(Holm across 6 contrasts) ---\n")
  print(wald[[nm]], n = Inf)
}

# Save results ----------------------------------------------------------------
saveRDS(
  list(
    excess = excess,
    wald = wald,
    n_reps = n_reps
  ),
  here("Data", "bootstrap_sensitivity_results.RDS")
)
cat("\nBootstrap sensitivity analysis complete. Results saved to Data/bootstrap_sensitivity_results.RDS\n")

# LaTeX tables ---------------------------------------------------------------
fmt_ci <- function(lo, hi) sprintf("(%.3f, %.3f)", lo, hi)
fmt_p <- function(p) ifelse(p < 0.001, "$<$0.001", sprintf("%.3f", p))

build_bs_table <- function(baseline_key, baseline_label, label, caption) {
  ex <- excess[[baseline_key]]
  w1 <- wald[[paste0(baseline_key, "_m1")]]
  w3 <- wald[[paste0(baseline_key, "_m3")]]

  group_table <- ex$observed_summary |>
    left_join(ex$group_ci, by = "ego_rel") |>
    mutate(ego_rel = factor(ego_rel, levels = groups)) |>
    arrange(ego_rel)

  tex <- c(
    "\\begin{table}[htbp]",
    sprintf("\\caption{\\label{%s}%s}", label, caption),
    "\\centering",
    "\\scriptsize",
    "\\textit{Panel A: Group-level excess in-group tie rate (descriptive)}\\\\[2pt]",
    "\\begin{tabular}{lrrrrr}",
    "\\toprule",
    sprintf("Group & $n$ Egos & $n$ Ties & Observed Rate & Baseline Rate & Excess (95\\%% CI) \\\\"),
    "\\midrule"
  )
  for (i in seq_len(nrow(group_table))) {
    r <- group_table[i, ]
    tex <- c(tex, sprintf(
      "%s & %d & %s & %.3f & %.3f & %.3f %s \\\\",
      r$ego_rel, r$n_egos, format(r$n_ties, big.mark = ","), r$observed_rate, r$baseline_rate,
      r$boot_mean_excess, fmt_ci(r$ci_lo, r$ci_hi)
    ))
  }
  tex <- c(
    tex,
    "\\bottomrule",
    sprintf(
      "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Baseline: %s. The excess is a descriptive quantity: for a fixed in-group odds ratio it varies with the group's baseline share, so it should not be compared across groups of different sizes. Panels C--D (log-odds) are the basis for group contrasts. The bootstrap uses the baseline sample (no covariate filtering).} \\\\",
      baseline_label
    ),
    "\\end{tabular}",
    "\\\\[8pt]",
    "\\textit{Panel B: Pairwise differences in excess rate (descriptive)}\\\\[2pt]",
    "\\begin{tabular}{llrrc}",
    "\\toprule",
    "Group 1 & Group 2 & Mean Diff. & 95\\% CI & Excludes 0 \\\\",
    "\\midrule"
  )
  for (i in seq_len(nrow(ex$pairwise_ci))) {
    r <- ex$pairwise_ci[i, ]
    tex <- c(tex, sprintf(
      "%s & %s & %.3f & %s & %s \\\\",
      r$group1, r$group2, r$mean_diff, fmt_ci(r$ci_lo, r$ci_hi),
      ifelse(r$excludes_zero, "Yes", "No")
    ))
  }
  tex <- c(
    tex,
    "\\bottomrule",
    "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Unique egos are resampled with replacement, separately within each group, so that each resampled ego's ties move together. Panel B differences are valid because each group's replicates are drawn independently.} \\\\",
    "\\end{tabular}",
    "\\\\[8pt]",
    "\\textit{Panel C: Wald tests of pairwise equality, pooled log-odds coefficients (Model 1)}\\\\[2pt]",
    "\\begin{tabular}{llrrrrr}",
    "\\toprule",
    "Group 1 & Group 2 & Log-Odds Diff. (G1 $-$ G2) & SE & $\\chi^2$ & $p$ & Holm $p$ \\\\",
    "\\midrule"
  )
  for (i in seq_len(nrow(w1))) {
    r <- w1[i, ]
    tex <- c(tex, sprintf(
      "%s & %s & %.3f & %.3f & %.3f & %s & %s \\\\",
      r$group1, r$group2, r$log_odds_diff, r$se, r$chisq, fmt_p(r$p_value), fmt_p(r$p_holm)
    ))
  }
  tex <- c(
    tex,
    "\\bottomrule",
    "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Model 1 (offset only), same analytic sample as Table~\\ref{tab:pooled-interaction-reg}, ego-clustered vcov. Catholic-vs-X rows are Catholic minus X. Holm-adjusted across all six contrasts.} \\\\",
    "\\end{tabular}",
    "\\\\[8pt]",
    "\\textit{Panel D: Wald tests of pairwise equality, pooled log-odds coefficients (Model 3)}\\\\[2pt]",
    "\\begin{tabular}{llrrrrr}",
    "\\toprule",
    "Group 1 & Group 2 & Log-Odds Diff. (G1 $-$ G2) & SE & $\\chi^2$ & $p$ & Holm $p$ \\\\",
    "\\midrule"
  )
  for (i in seq_len(nrow(w3))) {
    r <- w3[i, ]
    tex <- c(tex, sprintf(
      "%s & %s & %.3f & %.3f & %.3f & %s & %s \\\\",
      r$group1, r$group2, r$log_odds_diff, r$se, r$chisq, fmt_p(r$p_value), fmt_p(r$p_holm)
    ))
  }
  c(
    tex,
    "\\bottomrule",
    "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Identical contrasts to Panel C, on the Model 3 specification (structural foci, demographic homophily, salience, and ego/alter degree controls). Holm-adjusted across all six contrasts.} \\\\",
    "\\end{tabular}",
    "\\end{table}"
  )
}

writeLines(
  build_bs_table(
    "cohort",
    "ego-cohort composition (primary)",
    "tab:bootstrap-sensitivity",
    "Robustness Check: Ego-Level Cluster Bootstrap and Wald Tests, Ego-Cohort Opportunity Baseline (Waves 3--8, 2,000 replicates)."
  ),
  here("Tabs", "tbl-bootstrap-sensitivity.tex")
)
writeLines(
  build_bs_table(
    "pool",
    "nominated-alter pool (sensitivity)",
    "tab:bootstrap-sensitivity-pool",
    "Sensitivity Analysis: Ego-Level Cluster Bootstrap and Wald Tests, Nominated-Alter Pool Opportunity Baseline (Waves 3--8, 2,000 replicates)."
  ),
  here("Tabs", "tbl-bootstrap-sensitivity-pool.tex")
)
cat("Tables saved to Tabs/tbl-bootstrap-sensitivity.tex and Tabs/tbl-bootstrap-sensitivity-pool.tex\n")
