# Header ------------------------------------------------------------------
# Title: 07_yules_q_permutation_test
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-23
# Revised: 2026-10-23 - two null distributions. The observed Q is computed from
#          the tie table alone, so it does not depend on the opportunity baseline.
#          The null does. "Pool" null redraws alter religion from the wave's
#          nominated-alter composition (unchanged from the previous version, same
#          seed, so those rows reproduce). "Cohort" null redraws from the Wave 1
#          composition of egos. p-values are reported two-sided and one-sided.
# Purpose: Test the "universal inbreeding homophily" claim (Q > 0 for every group
#          and wave) against degree-preserving permutation nulls.
#
#          These z-scores establish whether each group departs from its own
#          chance baseline. They should NOT be used to rank the relative strength
#          of homophily across groups of very different sizes: the null variance
#          scales with group size.

library(here)
library(readr)
library(dplyr)

groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")

df_netsurv <- read_csv(here('Data', 'NetWorkSurvey.csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey.csv'))

prep_wave <- function(w) {
  df_netsurv |>
    filter(wave == w) |>
    left_join(df_basicsurv, by = "egoid") |>
    # family == FALSE excludes on-campus family ties (e.g. siblings)
    filter(!is.na(yourelig_1), altrelucat == "Student", family == FALSE, !is.na(altrelig)) |>
    mutate(
      ego_rel = as.character(yourelig_1),
      alt_rel = case_when(
        altrelig == "NoReligion" ~ "No Religion",
        altrelig == "OtherReligion" ~ "Other Religion",
        TRUE ~ altrelig
      )
    ) |>
    filter(ego_rel %in% groups, alt_rel %in% groups) |>
    select(egoid, ego_rel, alt_rel)
}

# Cohort composition (Wave 1 religion of all egos with religion known)
cohort_shares <- df_basicsurv |>
  mutate(ego_rel = as.character(yourelig_1)) |>
  filter(ego_rel %in% groups) |>
  count(ego_rel) |>
  mutate(p = n / sum(n))
cohort_probs <- setNames(cohort_shares$p, cohort_shares$ego_rel)[groups]

yules_q_by_group <- function(dat) {
  m <- matrix(0, 4, 4, dimnames = list(groups, groups))
  cnt <- dat |> count(ego_rel, alt_rel)
  for (i in seq_len(nrow(cnt))) m[cnt$ego_rel[i], cnt$alt_rel[i]] <- cnt$n[i]
  sapply(groups, function(g) {
    a <- m[g, g]; b <- sum(m[g, setdiff(groups, g)])
    c <- sum(m[setdiff(groups, g), g]); d <- sum(m[setdiff(groups, g), setdiff(groups, g)])
    if ((a * d + b * c) == 0) NA else (a * d - b * c) / (a * d + b * c)
  })
}

# Null: ego_rel and tie count fixed; alter religion redrawn from `probs`
run_wave_null <- function(dat, probs, n_perm = 1000) {
  observed_q <- yules_q_by_group(dat)
  n_ties <- nrow(dat)
  null_q <- matrix(NA, nrow = n_perm, ncol = 4, dimnames = list(NULL, groups))
  for (r in seq_len(n_perm)) {
    null_q[r, ] <- yules_q_by_group(
      data.frame(
        ego_rel = dat$ego_rel,
        alt_rel = sample(groups, n_ties, replace = TRUE, prob = probs)
      )
    )
  }
  tibble::tibble(
    Group = groups,
    Observed_Q = observed_q,
    Null_Mean = colMeans(null_q, na.rm = TRUE),
    Null_SD = apply(null_q, 2, sd, na.rm = TRUE),
    p_one_sided = sapply(seq_along(groups), function(i) mean(null_q[, i] >= observed_q[i], na.rm = TRUE)),
    p_two_sided = sapply(seq_along(groups), function(i) {
      lo <- mean(null_q[, i] <= observed_q[i], na.rm = TRUE)
      hi <- mean(null_q[, i] >= observed_q[i], na.rm = TRUE)
      min(1, 2 * min(lo, hi))
    }),
    z_score = (observed_q - colMeans(null_q, na.rm = TRUE)) / apply(null_q, 2, sd, na.rm = TRUE)
  )
}

waves <- paste0("Wave", 1:8)
dat_by_wave <- lapply(setNames(waves, waves), prep_wave)

# Pool null (same seed and loop order as the previous version)
set.seed(6142)
res_pool <- bind_rows(lapply(waves, function(w) {
  dat <- dat_by_wave[[w]]
  pool_probs <- prop.table(table(dat$alt_rel))[groups]
  run_wave_null(dat, pool_probs, n_perm = 1000) |> mutate(Wave = w, .before = 1)
}))

# Cohort null (separate seed)
set.seed(6143)
res_cohort <- bind_rows(lapply(waves, function(w) {
  run_wave_null(dat_by_wave[[w]], cohort_probs, n_perm = 1000) |> mutate(Wave = w, .before = 1)
}))

res_null <- res_pool |>
  rename_with(~ paste0(.x, "_pool"), c(Null_Mean, Null_SD, p_one_sided, p_two_sided, z_score)) |>
  left_join(
    res_cohort |>
      rename_with(~ paste0(.x, "_cohort"), c(Null_Mean, Null_SD, p_one_sided, p_two_sided, z_score)) |>
      select(-Observed_Q),
    by = c("Wave", "Group")
  )

write_csv(res_null, here("Data", "yules_q_permutation_null.csv"))

# Generate LaTeX table -------------------------------------------------------
fmt_p <- function(p) ifelse(p < 0.001, "$<$0.001", sprintf("%.3f", p))

nonsig_cohort <- res_null |> filter(p_two_sided_cohort >= 0.05)
nonsig_label <- function(d, suffix) {
  if (nrow(d) == 0) "none" else
    paste0(d$Group, " (", gsub("Wave", "Wave ", d$Wave), ", $p = ",
           sprintf("%.3f", d[[paste0("p_two_sided_", suffix)]]), "$)", collapse = "; ")
}

tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{Robustness Check: Degree-Preserving Permutation Test of Yule's $Q$ (Waves 1--8).}",
  "\\label{tab:yules-q-null}",
  "\\centering",
  "\\footnotesize",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  " & & & \\multicolumn{3}{c}{Cohort null (primary)} & \\multicolumn{2}{c}{Pool null} \\\\",
  "\\cmidrule(lr){4-6} \\cmidrule(lr){7-8}",
  "Wave & Group & Observed $Q$ & Null Mean & $z$ & $p$ & $z$ & $p$ \\\\",
  "\\midrule"
)

for (w in waves) {
  block <- res_null |> filter(Wave == w)
  for (i in seq_len(nrow(block))) {
    r <- block[i, ]
    wave_label <- if (i == 1) gsub("Wave", "W", w) else ""
    tex <- c(tex, sprintf(
      "%s & %s & %.3f & %.3f & %.2f & %s & %.2f & %s \\\\",
      wave_label, r$Group, r$Observed_Q, r$Null_Mean_cohort, r$z_score_cohort,
      fmt_p(r$p_two_sided_cohort), r$z_score_pool, fmt_p(r$p_two_sided_pool)
    ))
  }
  if (w != "Wave8") tex <- c(tex, "\\addlinespace")
}

n_gw <- nrow(res_null)
tex <- c(
  tex,
  "\\bottomrule",
  sprintf(
    "\\multicolumn{8}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Null distributions (1,000 permutations per wave and per null) hold each ego's tie count and own religion fixed and redraw nominated alters' religion from either the cohort composition of egos (primary) or the wave's nominated-alter composition (pool). Observed $Q$ is computed from the tie table alone and is the same under both nulls. Observed $Q$ lies above its cohort-null mean in %d of %d group-waves. Two-sided permutation $p$-values (share of null draws at least as extreme as observed, doubled) are significant at $p<0.05$ in %d of %d group-waves under the cohort null (exceptions: %s) and in %d of %d under the pool null (exceptions: %s). Because null variance scales with group size, $z$-scores should not be compared across groups to infer a ranking of homophily strength.} \\\\",
    sum(res_null$Observed_Q > res_null$Null_Mean_cohort), n_gw,
    sum(res_null$p_two_sided_cohort < 0.05), n_gw, nonsig_label(res_null |> filter(p_two_sided_cohort >= 0.05), "cohort"),
    sum(res_null$p_two_sided_pool < 0.05), n_gw, nonsig_label(res_null |> filter(p_two_sided_pool >= 0.05), "pool")
  ),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tex, here("Tabs", "tbl-yules-q-null.tex"))
cat("Permutation null test complete. Table saved to Tabs/tbl-yules-q-null.tex\n")
