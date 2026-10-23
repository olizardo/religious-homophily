# Header ------------------------------------------------------------------
# Title: 11_sample_missingness
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Check whether the complete-case analytic sample differs by religious group,
#          and whether the group coefficients depend on how missingness is handled.
#          Both opportunity baselines are reported (cohort, pool).
#            A. Missingness of key variables by ego group (student, non-family ties).
#            B. Group composition: baseline sample vs complete-case analytic sample.
#            C. Model 1 on the full baseline sample vs the complete-case sample.
#            D. Models 2-3 with missing indicators instead of complete-case filtering
#               (roommates, same dorm, alter race; ego-race-not-coded egos kept).
# Output:   Tabs/tbl-missingness.tex, Data/missingness_summary.RDS

library(here)
library(readr)
library(dplyr)
library(sandwich)
library(lmtest)

groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")

env_pooled <- new.env()
invisible(capture.output(source(here("Code", "02_dyadic_models_pooled.R"), local = env_pooled)))
df_netsurv <- read_csv(here("Data", "NetWorkSurvey.csv"), show_col_types = FALSE)
df_basicsurv <- read_csv(here("Data", "BasicSurvey.csv"), show_col_types = FALSE)

# A. Missingness by ego group (student, non-family ties, waves 3-8) ----------
raw_ties <- df_netsurv |>
  filter(wave %in% paste0("Wave", 3:8)) |>
  left_join(df_basicsurv |> select(egoid, yourelig_1, race_1, discussrelig_2), by = "egoid") |>
  filter(!is.na(yourelig_1), altrelucat == "Student", family == FALSE) |>
  mutate(ego_rel = as.character(yourelig_1)) |>
  filter(ego_rel %in% groups)

missing_by_group <- raw_ties |>
  group_by(ego_rel) |>
  summarise(
    n_ties = n(),
    n_egos = n_distinct(egoid),
    `altrelig missing (%)` = 100 * mean(is.na(altrelig)),
    `roommates missing (%)` = 100 * mean(is.na(roommates)),
    `samedorm missing (%)` = 100 * mean(is.na(samedorm)),
    `alter race missing (%)` = 100 * mean(is.na(altwhite) | is.na(altblack) | is.na(altasian) | is.na(althisla)),
    .groups = "drop"
  )
ego_discuss_missing <- df_basicsurv |>
  filter(yourelig_1 %in% groups) |>
  group_by(group = yourelig_1) |>
  summarise(n_egos_b = n(), `discuss missing (%)` = 100 * mean(is.na(discussrelig_2)), .groups = "drop")
ego_race_not_coded <- df_basicsurv |>
  filter(yourelig_1 %in% groups) |>
  group_by(group = yourelig_1) |>
  summarise(`ego race not coded (%)` = 100 * mean(!(race_1 %in% c("White", "African-American", "Asian-American", "Latino/a"))), .groups = "drop")

# B. Composition: baseline sample vs complete-case sample -----------------
baseline_sample <- env_pooled$df_pooled |>
  filter(!is.na(same_religion), !is.na(offset_cohort), !is.na(offset_pool))
analytic_sample <- env_pooled$df_pooled_clean

composition <- bind_rows(
  baseline = baseline_sample |> count(ego_rel) |> mutate(share = 100 * n / sum(n)),
  analytic = analytic_sample |> count(ego_rel) |> mutate(share = 100 * n / sum(n)),
  .id = "sample"
)

# C. Model 1 on the baseline sample vs the analytic sample ----------------------
model1_fit <- function(data, offset_col) {
  m <- glm(as.formula(paste("same_religion ~ ego_rel + offset(", offset_col, ")")),
           family = binomial, data = data)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = data$egoid))
  ct[c("ego_relNo Religion", "ego_relOther Religion", "ego_relProtestant"), c(1, 2, 4)]
}
model1_compare <- bind_rows(lapply(c("cohort", "pool"), function(b) {
  oc <- paste0("offset_", b)
  base <- model1_fit(baseline_sample, oc)
  ana <- model1_fit(analytic_sample, oc)
  bind_rows(
    tibble::tibble(baseline = b, sample = "baseline", group = rownames(base), est = base[, 1], se = base[, 2], p = base[, 3]),
    tibble::tibble(baseline = b, sample = "analytic", group = rownames(ana), est = ana[, 1], se = ana[, 2], p = ana[, 3])
  )
}))

# D. Missing indicators instead of complete-case filtering -------------------
ms <- env_pooled$df_pooled |>
  filter(!is.na(same_religion), !is.na(offset_cohort), !is.na(offset_pool),
         !is.na(same_gender), !is.na(discuss_num), !is.na(close_num),
         !is.na(log_ego_degree), !is.na(log_alter_pop)) |>
  mutate(
    room_na = as.integer(is.na(roommates)),
    dorm_na = as.integer(is.na(samedorm)),
    race_na = as.integer(is.na(same_race)),
    roommates_ms = ifelse(is.na(roommates), FALSE, roommates),
    samedorm_ms = ifelse(is.na(samedorm), FALSE, samedorm),
    same_race_ms = ifelse(is.na(same_race), 0, same_race)
  )

covs_ms <- "same_gender + same_race_ms + roommates_ms + samedorm_ms + room_na + dorm_na + race_na + close_num + discuss_num"
degs <- "log_ego_degree + log_alter_pop"
group_terms <- c("ego_relNo Religion", "ego_relOther Religion", "ego_relProtestant")

fit_ms <- function(rhs, oc, data) {
  m <- glm(as.formula(paste("same_religion ~ ego_rel +", rhs, "+ offset(", oc, ")")),
           family = binomial, data = data)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = data$egoid))
  ct[group_terms, c(1, 2, 4), drop = FALSE]
}
ms_rhs <- list(m2 = covs_ms, m3 = paste(covs_ms, degs, sep = " + "))
missing_ind <- bind_rows(lapply(c("cohort", "pool"), function(b) {
  bind_rows(lapply(names(ms_rhs), function(m) {
    ct <- fit_ms(ms_rhs[[m]], paste0("offset_", b), ms)
    tibble::tibble(baseline = b, model = m, group = rownames(ct),
                   est = ct[, 1], se = ct[, 2], p = ct[, 3])
  }))
}))

# Race not coded: egos with Foreign Student / Other race stay in the sample, with
# same_race = 0 and an indicator. Compare with the complete-case model above.
cat("Ties with same_race missing in missing-indicator sample:", sum(ms$race_na), "\n")

# Print and save ----------------------------------------------------------
cat("\n--- A. Missingness by ego group ---\n"); print(missing_by_group, digits = 3)
cat("\n--- Ego-level discussion missingness ---\n"); print(ego_discuss_missing, digits = 3)
cat("\n--- Ego race not coded ---\n"); print(ego_race_not_coded, digits = 3)
cat("\n--- B. Composition (%) ---\n"); print(composition, digits = 3)
cat("\n--- C. Model 1: baseline vs analytic sample ---\n"); print(model1_compare, digits = 3, n = Inf)
cat("\n--- D. Missing-indicator models ---\n"); print(missing_ind, digits = 3, n = Inf)

saveRDS(
  list(missing_by_group = missing_by_group, ego_discuss_missing = ego_discuss_missing,
       ego_race_not_coded = ego_race_not_coded, composition = composition,
       model1_compare = model1_compare, missing_ind = missing_ind,
       n_baseline = nrow(baseline_sample), n_analytic = nrow(analytic_sample),
       n_missing_ind = nrow(ms)),
  here("Data", "missingness_summary.RDS")
)
cat("\nSample sizes: baseline", nrow(baseline_sample), "; analytic", nrow(analytic_sample),
    "; missing-indicator", nrow(ms), "\n")

# LaTeX --------------------------------------------------------------------
fmt_cell <- function(est, se, p) sprintf("%.3f%s (%.3f)", est,
  ifelse(p < 0.001, "***", ifelse(p < 0.01, "**", ifelse(p < 0.05, "*", ""))), se)
gl <- c("No Religion", "Other Religion", "Protestant")

panel_a <- c(
  "\\textit{Panel A: Missingness by ego group (student, non-family ties, Waves 3--8)}\\\\[2pt]",
  "\\begin{tabular}{lrrrrrr}", "\\toprule",
  "Ego group & Egos & Ties & Alter religion missing (\\%) & Roommate missing (\\%) & Same dorm missing (\\%) & Alter race missing (\\%) \\\\",
  "\\midrule",
  sprintf("%s & %d & %s & %.1f & %.1f & %.1f & %.1f \\\\",
          missing_by_group$ego_rel, missing_by_group$n_egos,
          format(missing_by_group$n_ties, big.mark = ","),
          missing_by_group$`altrelig missing (%)`, missing_by_group$`roommates missing (%)`,
          missing_by_group$`samedorm missing (%)`, missing_by_group$`alter race missing (%)`),
  "\\bottomrule", "\\end{tabular}", "\\\\[6pt]",
  "\\begin{tabular}{lrr}", "\\toprule",
  "Ego group & Egos with discussion frequency missing (\\%) & Egos with race outside the four coded categories (\\%) \\\\",
  "\\midrule",
  sprintf("%s & %.1f & %.1f \\\\",
          ego_discuss_missing$group, ego_discuss_missing$`discuss missing (%)`,
          ego_race_not_coded$`ego race not coded (%)`),
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

comp_w <- composition |>
  select(sample, ego_rel, share) |>
  tidyr::pivot_wider(names_from = sample, values_from = share)
panel_b <- c(
  "\\textit{Panel B: Tie composition by ego group (\\%)}\\\\[2pt]",
  "\\begin{tabular}{lrr}", "\\toprule",
  "Ego group & Baseline sample (10,046 ties) & Complete-case analytic sample \\\\",
  "\\midrule",
  sprintf("%s & %.1f & %.1f \\\\", comp_w$ego_rel, comp_w$baseline, comp_w$analytic),
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

panel_c <- c(
  "\\textit{Panel C: Model 1 coefficients (log-odds vs.\\ Catholic), baseline sample vs.\\ complete-case sample}\\\\[2pt]",
  "\\begin{tabular}{llrrrr}", "\\toprule",
  "Baseline & Group & \\multicolumn{2}{c}{Baseline sample} & \\multicolumn{2}{c}{Complete-case} \\\\",
  " & & Est. (SE) & $p$ & Est. (SE) & $p$ \\\\", "\\midrule",
  unlist(lapply(c("cohort", "pool"), function(b) {
    vapply(seq_along(gl), function(i) {
      bs <- model1_compare[model1_compare$baseline == b & model1_compare$sample == "baseline", ][i, ]
      an <- model1_compare[model1_compare$baseline == b & model1_compare$sample == "analytic", ][i, ]
      sprintf("%s & %s & %.3f (%.3f) & %s & %.3f (%.3f) & %s \\\\",
              ifelse(i == 1, ifelse(b == "cohort", "Cohort", "Pool"), ""), gl[i],
              bs$est, bs$se, ifelse(bs$p < 0.001, "$<$0.001", sprintf("%.3f", bs$p)),
              an$est, an$se, ifelse(an$p < 0.001, "$<$0.001", sprintf("%.3f", an$p)))
    }, character(1))
  })),
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

panel_d <- c(
  "\\textit{Panel D: Missing-indicator models (roommate, dorm, and race missingness coded with indicators; race-not-coded egos retained)}\\\\[2pt]",
  "\\begin{tabular}{llcc}", "\\toprule",
  "Baseline & Group & Model 2 & Model 3 \\\\", "\\midrule",
  unlist(lapply(c("cohort", "pool"), function(b) {
    vapply(seq_along(gl), function(i) {
      r2 <- missing_ind[missing_ind$baseline == b & missing_ind$model == "m2", ][i, ]
      r3 <- missing_ind[missing_ind$baseline == b & missing_ind$model == "m3", ][i, ]
      sprintf("%s & %s & %s & %s \\\\",
              ifelse(i == 1, ifelse(b == "cohort", "Cohort", "Pool"), ""), gl[i],
              fmt_cell(r2$est, r2$se, r2$p), fmt_cell(r3$est, r3$se, r3$p))
    }, character(1))
  })),
  "\\bottomrule", "\\end{tabular}"
)

tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{\\label{tab:missingness}Missingness, Sample Composition, and Missing-Indicator Sensitivity (Waves 3--8).}",
  "\\centering", "\\scriptsize",
  panel_a, panel_b, panel_c, panel_d,
  "\\\\[4pt]",
  sprintf("\\begin{minipage}{0.95\\textwidth}\\footnotesize \\textit{Note:} The baseline sample has %d ties and the complete-case analytic sample has %d. The missing-indicator sample (%d ties) keeps ties with missing roommate, dorm, or alter-race information and egos whose race is not one of the four coded categories; each missing item enters with an indicator, and the item is set to 0. Ego-clustered SEs. $^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.\\end{minipage}",
          nrow(baseline_sample), nrow(analytic_sample), nrow(ms)),
  "\\end{table}"
)
writeLines(tex, here("Tabs", "tbl-missingness.tex"))
cat("\nTable saved to Tabs/tbl-missingness.tex\n")
