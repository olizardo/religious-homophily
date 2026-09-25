# Header ------------------------------------------------------------------
# Title: 10_bootstrap_sensitivity
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Purpose: Formalize, as a reproducible script, the pooled bootstrap
#          sensitivity analysis cited in the Discussion (paper.tex) as
#          evidence that the ranking implied by the pooled logit
#          coefficients (Other Religion > Protestant approx No Religion)
#          is not statistically reliable, while the Catholic/non-Catholic
#          distinction is. This analysis previously existed only as an
#          ad hoc, unscripted result typed directly into the manuscript;
#          this script reproduces it from scratch on the current
#          family-tie-excluded analytic sample (Section 11, AGENTS.md).
#
#          Method: an ego-level cluster bootstrap, resampling unique egos
#          WITH REPLACEMENT separately within each religious group
#          (so that all of an ego's ties, across whatever waves they
#          appear in, are resampled as a single block -- respecting
#          within-ego clustering across waves). For each replicate, we
#          recompute, per group, the "excess in-group tie rate": the
#          observed same-religion tie rate minus the wave-specific
#          opportunity/chance baseline (the same `prop` used to build the
#          logit offset in Code/02_dyadic_models_pooled.R). This excess
#          statistic is directly comparable across groups of different
#          sizes because it is already baseline-adjusted, unlike a raw
#          in-group tie rate.
#
#          We report each group's excess rate with a percentile bootstrap
#          95% CI, and the pairwise-difference 95% CI between every pair
#          of groups (valid because the group-level bootstraps are drawn
#          independently of one another).

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)

set.seed(6284)

groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")
n_reps <- 2000

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

# Prepare Pooled Long-Format Dyadic Dataset (Waves 3-8) -------------------
# Identical to the Model 1 (baseline) data-prep block in
# Code/02_dyadic_models_pooled.R -- no structural/degree covariates are
# needed here, only the outcome and the opportunity-offset baseline.
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

# Wave-specific alter religious proportions (opportunity/chance baseline)
wave_alter_props <- df_all |>
  group_by(wave, alt_rel) |>
  count() |>
  group_by(wave) |>
  mutate(prop = n / sum(n)) |>
  ungroup()

df_pooled <- df_all |>
  left_join(wave_alter_props |> select(wave, alt_rel, prop), by = c("wave" = "wave", "ego_rel" = "alt_rel")) |>
  mutate(same_religion = ifelse(ego_rel == alt_rel, 1, 0)) |>
  select(egoid, ego_rel, same_religion, prop)

cat("Total pooled ties for bootstrap (Waves 3-8):", nrow(df_pooled), "\n")
cat("Total unique egos who contribute ties:", n_distinct(df_pooled$egoid), "\n\n")

# Observed (point estimate) excess in-group tie rate by group -------------
observed_summary <- df_pooled |>
  group_by(ego_rel) |>
  summarise(
    n_egos = n_distinct(egoid),
    n_ties = n(),
    observed_rate = mean(same_religion),
    baseline_rate = mean(prop),
    excess = observed_rate - baseline_rate,
    .groups = "drop"
  )

cat("--- Observed excess in-group tie rate by group ---\n")
print(observed_summary)

# Ego-level cluster bootstrap ----------------------------------------------
# For each group, pre-split ties into a list keyed by egoid so that a
# resampled ego contributes ALL of their ties (across all waves) as one
# block, respecting within-ego clustering.
boot_excess <- function(g) {
  dat_g <- df_pooled |> filter(ego_rel == g)
  egos_g <- unique(dat_g$egoid)
  same_by_ego <- split(dat_g$same_religion, dat_g$egoid)
  prop_by_ego <- split(dat_g$prop, dat_g$egoid)

  replicate(n_reps, {
    boot_ids <- sample(egos_g, length(egos_g), replace = TRUE)
    same_vec <- unlist(same_by_ego[as.character(boot_ids)], use.names = FALSE)
    prop_vec <- unlist(prop_by_ego[as.character(boot_ids)], use.names = FALSE)
    mean(same_vec) - mean(prop_vec)
  })
}

boot_results <- lapply(groups, boot_excess)
names(boot_results) <- groups

# Per-group bootstrap point estimate + 95% percentile CI -------------------
group_ci <- lapply(groups, function(g) {
  b <- boot_results[[g]]
  tibble::tibble(
    ego_rel = g,
    boot_mean_excess = mean(b),
    ci_lo = quantile(b, 0.025),
    ci_hi = quantile(b, 0.975)
  )
})
group_ci <- bind_rows(group_ci)

cat("\n--- Bootstrap excess-rate estimate and 95% CI by group ---\n")
print(group_ci)

# Pairwise differences between groups' excess rates ------------------------
# Valid because each group's bootstrap replicates are drawn independently.
pairs <- combn(groups, 2, simplify = FALSE)
pairwise_ci <- lapply(pairs, function(p) {
  diff_vec <- boot_results[[p[1]]] - boot_results[[p[2]]]
  tibble::tibble(
    group1 = p[1],
    group2 = p[2],
    mean_diff = mean(diff_vec),
    ci_lo = quantile(diff_vec, 0.025),
    ci_hi = quantile(diff_vec, 0.975),
    excludes_zero = (quantile(diff_vec, 0.025) > 0) | (quantile(diff_vec, 0.975) < 0)
  )
})
pairwise_ci <- bind_rows(pairwise_ci)

cat("\n--- Pairwise differences in excess rate (95% CI) ---\n")
print(pairwise_ci, n = Inf)

# Save results --------------------------------------------------------------
saveRDS(
  list(
    observed_summary = observed_summary,
    boot_results = boot_results,
    group_ci = group_ci,
    pairwise_ci = pairwise_ci,
    n_reps = n_reps
  ),
  here("Data", "bootstrap_sensitivity_results.RDS")
)

cat("\nBootstrap sensitivity analysis complete. Results saved to Data/bootstrap_sensitivity_results.RDS\n")

# Generate LaTeX Supplementary Table ---------------------------------------
fmt_ci <- function(lo, hi) sprintf("(%.3f, %.3f)", lo, hi)

group_table <- observed_summary |>
  left_join(group_ci, by = "ego_rel") |>
  mutate(ego_rel = factor(ego_rel, levels = groups)) |>
  arrange(ego_rel)

tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{Robustness Check: Ego-Level Cluster Bootstrap Sensitivity Analysis of Excess In-Group Tie Rates (Waves 3--8, 2,000 replicates).}",
  "\\label{tab:bootstrap-sensitivity}",
  "\\centering",
  "\\small",
  "\\textit{Panel A: Group-level excess in-group tie rate}\\\\[2pt]",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Group & $n$ Egos & $n$ Ties & Observed Rate & Baseline Rate & Excess (95\\% CI) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(group_table))) {
  r <- group_table[i, ]
  tex <- c(tex, sprintf(
    "%s & %d & %d & %.3f & %.3f & %.3f %s \\\\",
    r$ego_rel, r$n_egos, r$n_ties, r$observed_rate, r$baseline_rate,
    r$boot_mean_excess, fmt_ci(r$ci_lo, r$ci_hi)
  ))
}

tex <- c(
  tex,
  "\\bottomrule",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Catholic's own excess (95\\% CI excludes zero) indicates that even the religious majority exhibits some in-group tie preference beyond pure chance mixing; the substantive question of interest is not whether any group departs from chance (all four do, per Table~\\ref{tab:yules-q-null} and here), but the \\textit{relative magnitude} of that departure across groups, which Panel B addresses directly.} \\\\",
  "\\end{tabular}",
  "\\\\[8pt]",
  "\\textit{Panel B: Pairwise differences in excess rate}\\\\[2pt]",
  "\\begin{tabular}{llrrc}",
  "\\toprule",
  "Group 1 & Group 2 & Mean Diff. & 95\\% CI & Excludes 0 \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(pairwise_ci))) {
  r <- pairwise_ci[i, ]
  tex <- c(tex, sprintf(
    "%s & %s & %.3f & %s & %s \\\\",
    r$group1, r$group2, r$mean_diff, fmt_ci(r$ci_lo, r$ci_hi),
    ifelse(r$excludes_zero, "Yes", "No")
  ))
}

tex <- c(
  tex,
  "\\bottomrule",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Unique egos are resampled with replacement, separately within each religious group, so that all of a resampled ego's ties (across whatever waves they contribute to) move together as a single block. Excess rate is the observed same-religion tie rate minus the wave-specific opportunity/chance baseline used to construct the logit offset in the pooled dyadic regressions (Table~\\ref{tab:pooled-interaction-reg}); this baseline-adjusted quantity is comparable across groups of unequal size, unlike a raw tie rate or a log-odds coefficient. Panel B differences are valid because each group's bootstrap replicates are drawn independently of the other groups'.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tex, here("Tabs", "tbl-bootstrap-sensitivity.tex"))
cat("Supplementary table saved to Tabs/tbl-bootstrap-sensitivity.tex\n")
