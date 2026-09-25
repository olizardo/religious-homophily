# Header ------------------------------------------------------------------
# Title: 02b_build_pooled_table
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-24
# Purpose: Close the manuscript's last reproducibility gap. Fits the pooled
#          dyadic models (Code/02_dyadic_models_pooled.R) and the Time x
#          Religion interaction model (Code/02_dyadic_models_interaction.R),
#          then builds Tabs/tbl-pooled-interaction-reg.tex (Table 2 in
#          paper.tex) directly from the fitted model objects. Previously
#          this table was hand-assembled from console output and could
#          silently drift out of sync with the scripts that "produced" it
#          (see AGENTS.md Section 0/6 for a past instance of exactly this
#          failure mode). This script sources the two canonical model
#          scripts as the single source of truth for the data-prep and
#          model specifications, so there is no duplicated/divergent
#          data-cleaning logic here -- only table assembly.

# Load libraries -----------------------------------------------------------
library(here)
library(dplyr)

# Fit models via the canonical scripts -------------------------------------
# Sourcing (rather than reimplementing) guarantees this table can never
# drift from the actual model specifications: model1_pooled/model2_pooled/
# model3_pooled/m1_clustered/m2_clustered/m3_clustered/df_pooled_clean come
# from 02_dyadic_models_pooled.R; model_interaction/clustered_results come
# from 02_dyadic_models_interaction.R.
source(here("Code", "02_dyadic_models_pooled.R"))
source(here("Code", "02_dyadic_models_interaction.R"))

models <- list(
  "Model 1" = m1_clustered,
  "Model 2" = m2_clustered,
  "Model 3 (+Degree)" = m3_clustered,
  "Interaction (+Degree)" = clustered_results
)

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

row_line <- function(label, varname) {
  cells <- sapply(models, fmt_cell, varname = varname)
  paste(label, paste(cells, collapse = " & "), sep = " & ") |> paste0(" \\\\")
}

# Table rows -----------------------------------------------------------------
# (label, model coefficient name) pairs, in display order.
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
  c("Alter: Popularity (log in-deg.)", "log_alter_pop"),
  c("Tie: Wave Number", "wave_num"),
  c("Ego: No Religion x Wave", "ego_relNo Religion:wave_num"),
  c("Ego: Other Religion x Wave", "ego_relOther Religion:wave_num"),
  c("Ego: Protestant x Wave", "ego_relProtestant:wave_num")
)

body_rows <- sapply(row_specs, function(spec) {
  if (identical(spec, NA)) return(" \\\\")
  row_line(spec[1], spec[2])
})

# Group sample sizes (fully-adjusted pooled sample, Models 2/3) ------------
group_n <- df_pooled_clean |>
  group_by(ego_rel) |>
  summarise(n_egos = n_distinct(egoid), n_ties = n(), .groups = "drop") |>
  mutate(ego_rel = factor(ego_rel, levels = c("Catholic", "No Religion", "Other Religion", "Protestant"))) |>
  arrange(ego_rel)

n_other_relig <- group_n$n_egos[group_n$ego_rel == "Other Religion"]

group_n_rows <- sprintf(
  "%s & \\multicolumn{4}{l}{%s / %s} \\\\",
  group_n$ego_rel,
  format(group_n$n_egos, big.mark = ",", trim = TRUE),
  format(group_n$n_ties, big.mark = ",", trim = TRUE)
)

# Dynamic footnote figures --------------------------------------------------
# Pull the actual p-values for the degree terms so the footnote's stated
# range can never silently go stale relative to the fitted models.
p_degree <- c(
  get_p(m3_clustered, "log_ego_degree"),
  get_p(clustered_results, "log_ego_degree")
)
p_degree_lo <- sprintf("%.2f", min(p_degree, na.rm = TRUE))
p_degree_hi <- sprintf("%.2f", max(p_degree, na.rm = TRUE))

# Assemble LaTeX -------------------------------------------------------------
tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{\\label{tab:pooled-interaction-reg}Primary Analysis: Pooled Longitudinal and Interaction Models (Waves 3-8, Clustered SEs).}",
  "\\centering",
  "\\scriptsize",
  "\\resizebox{\\textwidth}{!}{%",
  "\\begin{tabular}[t]{lllll}",
  "\\toprule",
  "  & Model 1 & Model 2 & Model 3 (+Degree) & Interaction (+Degree)\\\\",
  "\\midrule",
  body_rows,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Group sample sizes (unique egos / dyadic ties), Waves 3--8 pooled, fully-adjusted sample}}\\\\",
  group_n_rows,
  "\\bottomrule",
  "\\multicolumn{5}{l}{\\rule{0pt}{1em}\\textit{Note:} $^{*} p < 0.05$; $^{**} p < 0.01$; $^{***} p < 0.001$}\\\\",
  sprintf(
    "\\multicolumn{5}{p{1.0\\textwidth}}{\\footnotesize Egos are counted once even if they contribute ties across multiple waves; standard errors clustered by egoid throughout. On-campus family ties (e.g., siblings both enrolled and nominating each other) are excluded from the analytic sample throughout, so all reported ties are nominations coded as student (non-family) relationships. Model 3 and the Interaction model add each ego's log out-degree (nominations made that wave) and each alter's log in-degree (nominations received that wave), computed from the full wave-specific nomination roster, to test whether opportunity-adjusted homophily reflects a degree/activity confound rather than affiliation itself (Reviewer 1). Neither degree term meaningfully attenuates the three group coefficients, though ego activity is itself marginally associated with same-religion tie formation ($p \\approx %s$--$%s$). The Other Religion group's small N (%d egos across the entire six-wave panel) implies substantially lower precision for its coefficient than for the other groups; see Results for a bootstrap sensitivity analysis.}\\\\",
    p_degree_lo, p_degree_hi, n_other_relig
  ),
  "\\end{tabular}",
  "}",
  "\\end{table}"
)

writeLines(tex, here("Tabs", "tbl-pooled-interaction-reg.tex"))
cat("\nTable saved to Tabs/tbl-pooled-interaction-reg.tex\n")
