# Header ------------------------------------------------------------------
# Title: 08_baseline_sensitivity
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Sensitivity of the group and headline results to the opportunity
#          baseline. Two baselines are reported as co-primary:
#            - "cohort": ego-cohort religious composition (Wave 1, time-invariant)
#            - "pool":   wave-specific composition of nominated student alters
#          A third, "loo" (leave-own-ego-out pool), removes each ego's own nominations
#          from the pool it is compared against. This removes the ego's own
#          feedback into the baseline but not group-level feedback.
#          Also reported: a single non-Catholic indicator (headline test), the
#          baseline share at which each group's contrast reaches zero, and a free
#          offset coefficient (identified only under the pool baseline).
# Output:   Tabs/tbl-baseline-sensitivity.tex, Data/baseline_sensitivity.RDS

# Load libraries -----------------------------------------------------------
library(here)
library(dplyr)
library(sandwich)
library(lmtest)

# Canonical data preparation (both offsets) --------------------------------
env_pooled <- new.env()
source(here("Code", "02_dyadic_models_pooled.R"), local = env_pooled)
d <- env_pooled$df_pooled_clean
all_ties <- env_pooled$df_all

# Leave-own-ego-out pool offset --------------------------------------------
# For tie (i, w) in group g_i: share of g_i among nominations made by OTHER egos
# in wave w = (n_wg - a_iw) / (N_w - b_iw), where a_iw is ego i's nominations to
# its own group and b_iw is ego i's total nominations in wave w.
wave_totals <- all_ties |> count(wave, name = "N_w")
group_totals <- all_ties |> count(wave, alt_rel, name = "n_wg")
ego_totals <- all_ties |> count(wave, egoid, name = "b_iw")
ego_own <- all_ties |>
  filter(alt_rel == ego_rel) |>
  count(wave, egoid, name = "a_iw")

d_loo <- d |>
  left_join(group_totals |> rename(ego_rel = alt_rel), by = c("wave", "ego_rel")) |>
  left_join(wave_totals, by = "wave") |>
  left_join(ego_totals, by = c("wave", "egoid")) |>
  left_join(ego_own, by = c("wave", "egoid")) |>
  mutate(
    a_iw = coalesce(a_iw, 0L),
    p_loo = (n_wg - a_iw) / (N_w - b_iw),
    offset_loo = log(p_loo / (1 - p_loo)),
    non_cath = as.integer(ego_rel != "Catholic")
  )

cat("Ties with leave-own-ego-out share outside (0,1):",
    sum(d_loo$p_loo <= 0 | d_loo$p_loo >= 1, na.rm = TRUE), "\n")
cat("Ties with missing leave-own-ego-out offset:", sum(is.na(d_loo$offset_loo)), "\n")

# Model specifications ----------------------------------------------------
covs <- "same_gender + same_race + roommates + samedorm + close_num + discuss_num"
degs <- "log_ego_degree + log_alter_pop"
f_group <- list(
  m1 = "ego_rel",
  m2 = paste("ego_rel", covs, sep = " + "),
  m3 = paste("ego_rel", covs, degs, sep = " + ")
)
f_head <- lapply(f_group, function(s) sub("ego_rel", "non_cath", s))
baselines <- c(cohort = "offset_cohort", pool = "offset_pool", loo = "offset_loo")

fit_clustered <- function(rhs, offset_col, data) {
  f <- as.formula(paste("same_religion ~", rhs, "+ offset(", offset_col, ")"))
  m <- glm(f, family = binomial, data = data)
  list(model = m, test = coeftest(m, vcov = vcovCL(m, cluster = data$egoid)))
}

# Headline: single non-Catholic indicator --------------------------------
headline <- bind_rows(lapply(names(baselines), function(b) {
  bind_rows(lapply(names(f_head), function(m) {
    ct <- fit_clustered(f_head[[m]], baselines[[b]], d_loo)$test
    tibble::tibble(baseline = b, model = m, est = ct["non_cath", 1],
                   se = ct["non_cath", 2], p = ct["non_cath", 4])
  }))
}))

# Group coefficients (Models 1 and 3) under each baseline ------------------
group_terms <- c("ego_relNo Religion", "ego_relOther Religion", "ego_relProtestant")
group_coefs <- bind_rows(lapply(names(baselines), function(b) {
  bind_rows(lapply(c("m1", "m3"), function(m) {
    ct <- fit_clustered(f_group[[m]], baselines[[b]], d_loo)$test
    tibble::tibble(baseline = b, model = m, term = group_terms,
                   est = ct[group_terms, 1], se = ct[group_terms, 2], p = ct[group_terms, 4])
  }))
}))

# Break-even baseline share ------------------------------------------------
# Model 1 under the pool baseline. Holding the Catholic share at its cohort value,
# find the share of each group s* at which its cohort-baseline contrast would be
# zero: logit(s*) = logit(s_C) + beta_g + [off_pool_g - off_pool_C].
# The offsets are group means over ties, so this is approximate.
m1_pool <- fit_clustered(f_group$m1, "offset_pool", d)$model
beta_pool <- c(Catholic = 0, setNames(coef(m1_pool)[group_terms], c("No Religion", "Other Religion", "Protestant")))
group_shares <- d |>
  group_by(ego_rel) |>
  summarise(
    pool_share = mean(prop_pool),
    cohort_share = first(prop_cohort),
    off_pool = mean(offset_pool),
    .groups = "drop"
  )
off_C_cohort <- qlogis(group_shares$cohort_share[group_shares$ego_rel == "Catholic"])
off_pool_C <- group_shares$off_pool[group_shares$ego_rel == "Catholic"]
break_even <- group_shares |>
  filter(ego_rel != "Catholic") |>
  mutate(
    beta_pool_m1 = beta_pool[ego_rel],
    break_even_share = plogis(off_C_cohort + beta_pool_m1 + (off_pool - off_pool_C))
  ) |>
  select(ego_rel, pool_share, cohort_share, beta_pool_m1, break_even_share)

# Free offset coefficient (pool baseline only) ------------------------------
# With the cohort baseline the offset is constant within group and collinear with the
# group indicators, so it is not identified there. Under the pool baseline it varies by
# wave, so the coefficient is identified, though weakly.
free_offset <- {
  m <- glm(same_religion ~ ego_rel + offset_pool, family = binomial, data = d)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = d$egoid))
  est <- ct["offset_pool", 1]
  se <- ct["offset_pool", 2]
  tibble::tibble(est = est, se = se, p_vs_zero = ct["offset_pool", 4],
                 z_vs_one = (est - 1) / se, p_vs_one = 2 * pnorm(-abs((est - 1) / se)))
}

# Print -------------------------------------------------------------------
cat("\n--- Headline: single non-Catholic indicator ---\n"); print(headline, n = Inf)
cat("\n--- Group coefficients by baseline ---\n"); print(group_coefs, n = Inf)
cat("\n--- Break-even shares (Model 1, pool) ---\n"); print(break_even)
cat("\n--- Free offset coefficient (pool) ---\n"); print(free_offset)

saveRDS(
  list(headline = headline, group_coefs = group_coefs, break_even = break_even,
       free_offset = free_offset),
  here("Data", "baseline_sensitivity.RDS")
)

# LaTeX --------------------------------------------------------------------
fmt_cell <- function(est, se, p) sprintf("%.3f%s (%.3f)", est,
  ifelse(p < 0.001, "***", ifelse(p < 0.01, "**", ifelse(p < 0.05, "*", ""))), se)
b_lab <- c(cohort = "Cohort (primary)", pool = "Alter pool", loo = "Leave-own-ego-out pool")

panel_a <- c(
  "\\textit{Panel A: Single non-Catholic indicator (headline test)}\\\\[2pt]",
  "\\begin{tabular}{lccc}", "\\toprule",
  "Baseline & Model 1 & Model 2 & Model 3 \\\\", "\\midrule",
  vapply(names(baselines), function(b) {
    cells <- vapply(names(f_head), function(m) {
      r <- headline[headline$baseline == b & headline$model == m, ]
      fmt_cell(r$est, r$se, r$p)
    }, character(1))
    paste(b_lab[[b]], paste(cells, collapse = " & "), sep = " & ") |> paste0(" \\\\")
  }, character(1)),
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

group_lab <- c("No Religion", "Other Religion", "Protestant")
panel_b <- c(
  "\\textit{Panel B: Group log-odds contrasts with Catholic under each baseline}\\\\[2pt]",
  "\\begin{tabular}{llcc}", "\\toprule",
  "Group & Baseline & Model 1 & Model 3 \\\\", "\\midrule",
  unlist(lapply(seq_along(group_terms), function(i) {
    vapply(names(baselines), function(b) {
      c1 <- group_coefs[group_coefs$baseline == b & group_coefs$model == "m1" & group_coefs$term == group_terms[i], ]
      c3 <- group_coefs[group_coefs$baseline == b & group_coefs$model == "m3" & group_coefs$term == group_terms[i], ]
      paste(if (b == "cohort") group_lab[i] else "", b_lab[[b]],
            fmt_cell(c1$est, c1$se, c1$p), fmt_cell(c3$est, c3$se, c3$p), sep = " & ") |> paste0(" \\\\")
    }, character(1))
  })),
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

panel_c <- c(
  "\\textit{Panel C: Break-even baseline share (Model 1, pool coefficients)}\\\\[2pt]",
  "\\begin{tabular}{lrrrr}", "\\toprule",
  "Group & Pool share & Cohort share & Model 1 (pool) & Break-even share \\\\", "\\midrule",
  sprintf("%s & %.1f\\%% & %.1f\\%% & %.3f & %.1f\\%% \\\\",
          break_even$ego_rel, 100 * break_even$pool_share, 100 * break_even$cohort_share,
          break_even$beta_pool_m1, 100 * break_even$break_even_share),
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

panel_d <- c(
  "\\textit{Panel D: Free offset coefficient (pool baseline; Model 1 covariates)}\\\\[2pt]",
  "\\begin{tabular}{lrrrr}", "\\toprule",
  "Estimate & SE & $p$ vs.\\ 0 & $p$ vs.\\ 1 \\\\", "\\midrule",
  sprintf("%.3f & %.3f & %.3f & %.3f \\\\", free_offset$est, free_offset$se,
          free_offset$p_vs_zero, free_offset$p_vs_one),
  "\\bottomrule", "\\end{tabular}"
)

tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{\\label{tab:baseline-sensitivity}Sensitivity to the Opportunity Baseline (Waves 3--8, ego-clustered SEs).}",
  "\\centering", "\\scriptsize",
  panel_a, panel_b, panel_c, panel_d,
  "\\\\[4pt]",
  "\\begin{minipage}{0.95\\textwidth}\\footnotesize \\textit{Note:} Cohort = Wave 1 religious composition of all egos with religion known (time-invariant). Pool = wave-specific composition of nominated student alters, which is partly the outcome. LOO pool = pool excluding each ego's own nominations. Panel A reports the coefficient on a single non-Catholic indicator. Panel C break-even shares hold the Catholic share at its cohort value and use group-mean offsets, so they are approximate. Panel D is identified only under the pool baseline. $^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.\\end{minipage}",
  "\\end{table}"
)
writeLines(tex, here("Tabs", "tbl-baseline-sensitivity.tex"))
cat("\nTable saved to Tabs/tbl-baseline-sensitivity.tex\n")
