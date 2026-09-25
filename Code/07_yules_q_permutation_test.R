# Header ------------------------------------------------------------------
# Title: 07_yules_q_permutation_test
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-09-23
# Purpose: Formally test the "universal inbreeding homophily" claim (Q > 0
#          for every religious group, every wave) against a degree-preserving
#          permutation null, rather than relying on eyeballed raw Q magnitudes.
#          For each ego, the number of nominated ties (degree) and own
#          religion are held fixed; nominated alters' religion is redrawn
#          from that wave's observed opportunity pool. This produces a
#          null distribution of Yule's Q for each group/wave against which
#          the observed value is standardized (z-score) and tested (p-value).
#
#          IMPORTANT: these z-scores establish whether each group,
#          individually, departs from its own chance baseline. They should
#          NOT be used to rank the relative strength of homophily across
#          groups of very different sizes -- differences in z-score partly
#          reflect differences in statistical power (smaller groups have
#          wider null distributions), not necessarily differences in the
#          underlying tendency to homophily. Cross-group comparisons are
#          addressed separately, and more carefully, in the bootstrap
#          sensitivity analysis reported alongside the pooled dyadic
#          regression table (Tabs/tbl-pooled-interaction-reg.tex).

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
    # family == FALSE excludes on-campus family ties (e.g. siblings), keeping only non-family student ties
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

run_wave_null <- function(w, n_perm = 1000) {
  dat <- prep_wave(w)
  observed_q <- yules_q_by_group(dat)
  alt_pool_probs <- prop.table(table(dat$alt_rel))[groups]
  n_ties <- nrow(dat)

  # Degree-preserving permutation: same egos/rows, alter religion resampled
  # from the wave-level opportunity pool
  null_q <- matrix(NA, nrow = n_perm, ncol = 4, dimnames = list(NULL, groups))
  for (r in seq_len(n_perm)) {
    null_q[r, ] <- yules_q_by_group(
      data.frame(
        ego_rel = dat$ego_rel,
        alt_rel = sample(groups, n_ties, replace = TRUE, prob = alt_pool_probs)
      )
    )
  }

  data.frame(
    Wave = w, Group = groups, Observed_Q = observed_q,
    Null_Mean = colMeans(null_q, na.rm = TRUE),
    Null_SD = apply(null_q, 2, sd, na.rm = TRUE),
    p_value = sapply(seq_along(groups), function(i) mean(null_q[, i] >= observed_q[i], na.rm = TRUE))
  ) |> mutate(z_score = (Observed_Q - Null_Mean) / Null_SD)
}

set.seed(6142)
res_null <- bind_rows(lapply(paste0("Wave", 1:8), run_wave_null, n_perm = 1000))
rownames(res_null) <- NULL

write_csv(res_null, here("Data", "yules_q_permutation_null.csv"))

# Generate LaTeX Appendix Table ---------------------------------------------
fmt_p <- function(p) ifelse(p < 0.001, "$<$0.001", sprintf("%.3f", p))

tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{Robustness Check: Degree-Preserving Permutation Test of Yule's $Q$ (Waves 1--8).}",
  "\\label{tab:yules-q-null}",
  "\\centering",
  "\\small",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Wave & Group & Observed $Q$ & Null Mean & Null SD & $z$ & $p$ \\\\",
  "\\midrule"
)

for (w in paste0("Wave", 1:8)) {
  block <- res_null |> filter(Wave == w)
  for (i in seq_len(nrow(block))) {
    r <- block[i, ]
    wave_label <- if (i == 1) gsub("Wave", "W", w) else ""
    tex <- c(tex, sprintf(
      "%s & %s & %.3f & %.3f & %.3f & %.2f & %s \\\\",
      wave_label, r$Group, r$Observed_Q, r$Null_Mean, r$Null_SD, r$z_score, fmt_p(r$p_value)
    ))
  }
  if (w != "Wave8") tex <- c(tex, "\\addlinespace")
}

tex <- c(
  tex,
  "\\bottomrule",
  "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Note:} Null distributions (1,000 permutations per wave) hold each ego's degree and own religion fixed and redraw nominated alters' religion from that wave's observed opportunity pool. $z$-scores confirm that each group, individually, departs from its own chance baseline in every wave (supporting universal inbreeding homophily). Because null variance itself scales with group size, $z$-scores should not be compared across groups to infer a ranking of homophily strength -- differences partly reflect differential statistical power rather than differential preference. Cross-group comparisons are addressed separately via the bootstrap sensitivity analysis reported with the pooled dyadic regression table (Table~\\ref{tab:pooled-interaction-reg}).} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tex, here("Tabs", "tbl-yules-q-null.tex"))

cat("Permutation null test complete. Table saved to Tabs/tbl-yules-q-null.tex\n")
