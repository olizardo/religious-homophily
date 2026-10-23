# Header ------------------------------------------------------------------
# Title: 02b_build_pooled_table
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Revised: 2026-10-23 - builds the primary table (cohort offset) and a parallel
#          sensitivity table (alter-pool offset) from the same fitted objects.
# Purpose: Fit the pooled dyadic models (Code/02_dyadic_models_pooled.R) and the
#          Time x Religion interaction model (Code/02_dyadic_models_interaction.R),
#          then build the regression tables directly from the fitted objects.
#          Sourcing the canonical scripts guarantees the tables cannot drift from
#          the model specifications.

# Load libraries -----------------------------------------------------------
library(here)
library(dplyr)

# Fit models via the canonical scripts -------------------------------------
# Each script is sourced into its own environment, so nothing is assigned into
# the global environment.
env_pooled <- new.env()
source(here("Code", "02_dyadic_models_pooled.R"), local = env_pooled)
env_interaction <- new.env()
source(here("Code", "02_dyadic_models_interaction.R"), local = env_interaction)

# Helpers -------------------------------------------------------------------
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else ""
}

fmt_cell <- function(m, varname) {
  if (is.null(m) || !(varname %in% rownames(m))) return("---")
  est <- m[varname, "Estimate"]
  se <- m[varname, "Std. Error"]
  p <- m[varname, "Pr(>|z|)"]
  sprintf("%.3f%s (%.3f)", est, stars(p), se)
}

get_p <- function(m, varname) {
  if (is.null(m) || !(varname %in% rownames(m))) return(NA_real_)
  m[varname, "Pr(>|z|)"]
}

# Table rows -----------------------------------------------------------------
row_specs <- list(
  c("Intercept", "(Intercept)"),
  NA, # blank spacer row
  c("Ego: No Religion", "ego_relNo Religion"),
  c("Ego: Other Religion", "ego_relOther Religion"),
  c("Ego: Protestant", "ego_relProtestant"),
  c("Tie: Gender Homophily", "same_gender"),
  c("Tie: Race Homophily", "same_race"),
  c("Tie: Roommates", "roommatesTRUE"),
  c("Tie: Same Dorm", "samedormTRUE"),
  c("Tie: Subjective Closeness", "close_num"),
  c("Ego: Religious Salience", "discuss_num"),
  c("Ego: Activity (log out-deg.)", "log_ego_degree"),
  c("Alter: Popularity (log, excl. focal tie)", "log_alter_pop"),
  c("Tie: Wave Number", "wave_num"),
  c("Ego: No Religion x Wave", "ego_relNo Religion:wave_num"),
  c("Ego: Other Religion x Wave", "ego_relOther Religion:wave_num"),
  c("Ego: Protestant x Wave", "ego_relProtestant:wave_num")
)

# Build one table for a given set of models --------------------------------
build_table <- function(models, joint_p, caption, label, group_n, footnote_extra) {
  row_line <- function(label, varname) {
    cells <- sapply(models, fmt_cell, varname = varname)
    paste(label, paste(cells, collapse = " & "), sep = " & ") |> paste0(" \\\\")
  }
  body_rows <- sapply(row_specs, function(spec) {
    if (identical(spec, NA)) return(" \\\\")
    row_line(spec[1], spec[2])
  })

  joint_row <- sprintf(
    "Joint test, group $\\times$ wave (3 df), $p$ & & & & %s \\\\",
    sprintf("%.3f", joint_p)
  )

  group_n_rows <- sprintf(
    "%s & \\multicolumn{4}{l}{%s / %s} \\\\",
    group_n$ego_rel,
    format(group_n$n_egos, big.mark = ",", trim = TRUE),
    format(group_n$n_ties, big.mark = ",", trim = TRUE)
  )

  p_degree <- c(
    get_p(models[[3]], "log_ego_degree"),
    get_p(models[[4]], "log_ego_degree")
  )
  p_degree_lo <- sprintf("%.2f", min(p_degree, na.rm = TRUE))
  p_degree_hi <- sprintf("%.2f", max(p_degree, na.rm = TRUE))

  c(
    "\\begin{table}[htbp]",
    sprintf("\\caption{\\label{%s}%s}", label, caption),
    "\\centering",
    "\\scriptsize",
    "\\resizebox{\\textwidth}{!}{%",
    "\\begin{tabular}[t]{lllll}",
    "\\toprule",
    "  & Model 1 & Model 2 & Model 3 (+Degree) & Interaction (+Degree)\\\\",
    "\\midrule",
    body_rows,
    joint_row,
    "\\midrule",
    "\\multicolumn{5}{l}{\\textit{Group sample sizes (unique egos / dyadic ties), Waves 3--8 pooled, fully-adjusted sample}}\\\\",
    group_n_rows,
    "\\bottomrule",
    "\\multicolumn{5}{l}{\\rule{0pt}{1em}\\textit{Note:} $^{*} p < 0.05$; $^{**} p < 0.01$; $^{***} p < 0.001$}\\\\",
    sprintf(
      "\\multicolumn{5}{p{1.0\\textwidth}}{\\footnotesize Egos are counted once even if they contribute ties across multiple waves; standard errors clustered by egoid throughout. On-campus family ties are excluded from the analytic sample. Model 3 and the Interaction model add each ego's log out-degree and the log of each alter's in-degree excluding the focal nomination, computed from the full wave-specific nomination roster. The ego activity term has $p \\approx %s$--$%s$ across Model 3 and the Interaction model. %s}\\\\",
      p_degree_lo, p_degree_hi, footnote_extra
    ),
    "\\end{tabular}",
    "}",
    "\\end{table}"
  )
}

group_n <- env_pooled$df_pooled_clean |>
  group_by(ego_rel) |>
  summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop") |>
  mutate(ego_rel = factor(ego_rel, levels = c("Catholic", "No Religion", "Other Religion", "Protestant"))) |>
  arrange(ego_rel)

joint_p_cohort <- env_interaction$wald_group_wave$p_value[env_interaction$wald_group_wave$baseline == "cohort"]
joint_p_pool <- env_interaction$wald_group_wave$p_value[env_interaction$wald_group_wave$baseline == "pool"]

primary_tex <- build_table(
  models = list(
    "Model 1" = env_pooled$m1_clustered,
    "Model 2" = env_pooled$m2_clustered,
    "Model 3 (+Degree)" = env_pooled$m3_clustered,
    "Interaction (+Degree)" = env_interaction$clustered_results
  ),
  joint_p = joint_p_cohort,
  caption = "Primary Analysis: Pooled Longitudinal and Interaction Models, Ego-Cohort Opportunity Offset (Waves 3-8, Clustered SEs).",
  label = "tab:pooled-interaction-reg",
  group_n = group_n,
  footnote_extra = "The opportunity offset is the log-odds of each group's share among egos (Wave 1 religion, time-invariant). The alternative offset, based on the composition of nominated alters in each wave, is reported in Table~\\ref{tab:pool-baseline-sensitivity}."
)

sensitivity_tex <- build_table(
  models = list(
    "Model 1" = env_pooled$m1_pool_clustered,
    "Model 2" = env_pooled$m2_pool_clustered,
    "Model 3 (+Degree)" = env_pooled$m3_pool_clustered,
    "Interaction (+Degree)" = env_interaction$clustered_results_pool
  ),
  joint_p = joint_p_pool,
  caption = "Sensitivity Analysis: Pooled Longitudinal and Interaction Models, Alter-Pool Opportunity Offset (Waves 3-8, Clustered SEs).",
  label = "tab:pool-baseline-sensitivity",
  group_n = group_n,
  footnote_extra = "The opportunity offset is the log-odds of each group's share among nominated student alters in each wave. This offset is endogenous to the outcome, since the nominations it is computed from are the ties being modeled. Models use the same analytic sample as Table~\\ref{tab:pooled-interaction-reg}."
)

writeLines(primary_tex, here("Tabs", "tbl-pooled-interaction-reg.tex"))
writeLines(sensitivity_tex, here("Tabs", "tbl-pool-baseline-sensitivity.tex"))
cat("\nTables saved to Tabs/tbl-pooled-interaction-reg.tex and Tabs/tbl-pool-baseline-sensitivity.tex\n")
