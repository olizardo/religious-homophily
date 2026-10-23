# Header ------------------------------------------------------------------
# Title: 09_inference_robustness
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Inference checks for the pooled Model 1 and Model 3 group coefficients,
#          under both opportunity baselines (cohort, pool), reported co-primary.
#            1. Ego-clustered vs two-way (ego and alter) clustered SEs.
#            2. Ego-cluster pairs bootstrap (resampling egos within group), percentile
#               CIs for each group coefficient and pairwise contrast.
#            3. Leave-one-ego-out influence on each group coefficient.
#          CR2 small-sample SEs and GEE are not included: clubSandwich and geepack
#          are not installed (installation requires approval).
# Output:   Tabs/tbl-inference-robustness.tex, Data/inference_robustness.RDS

# Load libraries -----------------------------------------------------------
library(here)
library(dplyr)
library(sandwich)
library(lmtest)

n_boot <- 1000

env_pooled <- new.env()
source(here("Code", "02_dyadic_models_pooled.R"), local = env_pooled)
d <- env_pooled$df_pooled_clean
dd <- as.data.frame(d)

covs <- "same_gender + same_race + roommates + samedorm + close_num + discuss_num"
degs <- "log_ego_degree + log_alter_pop"
rhs_list <- list(
  m1 = "ego_rel",
  m3 = paste("ego_rel", covs, degs, sep = " + ")
)
baselines <- c(cohort = "offset_cohort", pool = "offset_pool")
group_terms <- c("ego_relNo Religion", "ego_relOther Religion", "ego_relProtestant")
group_labels <- c("No Religion", "Other Religion", "Protestant")

fit_glm <- function(data, rhs, offset_col) {
  glm(as.formula(paste("same_religion ~", rhs, "+ offset(", offset_col, ")")),
      family = binomial, data = data)
}

# Contrast on a fitted model with a given vcov: returns estimate, SE, p
contrast <- function(m, V, terms, signs) {
  b <- coef(m)
  L <- setNames(rep(0, length(b)), names(b))
  L[terms] <- signs
  est <- sum(L * b)
  se <- sqrt(as.numeric(t(L) %*% V %*% L))
  c(est = est, se = se, p = pchisq((est / se)^2, df = 1, lower.tail = FALSE))
}

# Contrast set: group coefficients (X vs Catholic) and pairwise differences
contrast_defs <- list(
  "No Religion vs Catholic" = list(terms = group_terms[1], signs = 1),
  "Other Religion vs Catholic" = list(terms = group_terms[2], signs = 1),
  "Protestant vs Catholic" = list(terms = group_terms[3], signs = 1),
  "No Religion vs Other Religion" = list(terms = group_terms[1:2], signs = c(1, -1)),
  "No Religion vs Protestant" = list(terms = group_terms[c(1, 3)], signs = c(1, -1)),
  "Other Religion vs Protestant" = list(terms = group_terms[2:3], signs = c(1, -1))
)

# 1. Ego-clustered and two-way clustered vcov --------------------------------
cluster_check <- c(
  n_alterid_missing = sum(is.na(d$alterid)),
  n_alters_unique = n_distinct(d$alterid),
  n_egos = n_distinct(d$egoid)
)
cat("Clustering check:\n"); print(cluster_check)

fits <- list()
for (b in names(baselines)) for (m in names(rhs_list)) {
  fits[[paste(b, m, sep = "_")]] <- fit_glm(dd, rhs_list[[m]], baselines[[b]])
}

twoway <- lapply(fits, function(m) {
  vcovCL(m, cluster = dd[, c("egoid", "alterid")])
})
oneway <- lapply(fits, function(m) vcovCL(m, cluster = dd$egoid))

coef_table <- bind_rows(lapply(names(fits), function(k) {
  m <- fits[[k]]
  ct_1 <- coeftest(m, vcov = oneway[[k]])
  ct_2 <- coeftest(m, vcov = twoway[[k]])
  tibble::tibble(
    key = k,
    term = group_terms,
    est = coef(m)[group_terms],
    se_ego = ct_1[group_terms, 2],
    p_ego = ct_1[group_terms, 4],
    se_twoway = ct_2[group_terms, 2],
    p_twoway = ct_2[group_terms, 4]
  )
}))

contrast_twoway <- bind_rows(lapply(names(fits), function(k) {
  bind_rows(lapply(names(contrast_defs), function(nm) {
    cd <- contrast_defs[[nm]]
    r1 <- contrast(fits[[k]], oneway[[k]], cd$terms, cd$signs)
    r2 <- contrast(fits[[k]], twoway[[k]], cd$terms, cd$signs)
    tibble::tibble(key = k, contrast = nm,
                   est = r1["est"], p_ego = r1["p"], p_twoway = r2["p"])
  }))
}))

# 2. Ego-cluster pairs bootstrap ------------------------------------------
# Resample egos with replacement within each group; each resampled ego brings all of
# its ties. Refit the model in each replicate.
ego_group <- dd |> distinct(egoid, ego_rel)
egos_by_group <- split(ego_group$egoid, ego_group$ego_rel)
rows_by_ego <- split(seq_len(nrow(dd)), dd$egoid)

boot_contrasts <- function(rhs, offset_col, seed) {
  set.seed(seed)
  reps <- replicate(n_boot, {
    ids <- unlist(lapply(egos_by_group, function(e) sample(e, length(e), replace = TRUE)))
    rows <- unlist(rows_by_ego[as.character(ids)], use.names = FALSE)
    bd <- dd[rows, ]
    m <- tryCatch(fit_glm(bd, rhs, offset_col), error = function(e) NULL, warning = function(w) NULL)
    if (is.null(m) || !all(group_terms %in% names(coef(m)))) return(rep(NA_real_, 9))
    b <- coef(m)[group_terms]
    c(b[1], b[2], b[3], b[1] - b[2], b[1] - b[3], b[2] - b[3], -b[1], -b[2], -b[3])
  })
  reps <- t(reps)
  colnames(reps) <- c(group_labels,
                      "No Religion vs Other Religion", "No Religion vs Protestant",
                      "Other Religion vs Protestant",
                      "Catholic vs No Religion", "Catholic vs Other Religion", "Catholic vs Protestant")
  reps
}

boot_seeds <- c(cohort_m1 = 6286, cohort_m3 = 6287, pool_m1 = 6288, pool_m3 = 6289)
boot_list <- list()
for (k in names(boot_seeds)) {
  parts <- strsplit(k, "_")[[1]]
  boot_list[[k]] <- boot_contrasts(rhs_list[[parts[2]]], baselines[[parts[1]]], boot_seeds[[k]])
}
boot_failures <- sapply(boot_list, function(x) sum(is.na(x[, 1])))
cat("Bootstrap replicates failing to converge or lacking terms:\n"); print(boot_failures)

boot_ci <- bind_rows(lapply(names(boot_list), function(k) {
  x <- boot_list[[k]]
  tibble::tibble(
    key = k,
    contrast = colnames(x),
    lo = apply(x, 2, quantile, 0.025, na.rm = TRUE),
    hi = apply(x, 2, quantile, 0.975, na.rm = TRUE)
  )
}))

# 3. Leave-one-ego-out influence --------------------------------------------
loo_group <- bind_rows(lapply(names(fits), function(k) {
  parts <- strsplit(k, "_")[[1]]
  rhs <- rhs_list[[parts[2]]]
  off <- baselines[[parts[1]]]
  full <- coef(fits[[k]])[group_terms]
  egos <- unique(dd$egoid)
  est_mat <- t(vapply(egos, function(e) {
    bd <- dd[dd$egoid != e, ]
    tryCatch(coef(fit_glm(bd, rhs, off))[group_terms], error = function(err) rep(NA_real_, 3))
  }, numeric(3)))
  colnames(est_mat) <- group_labels
  bind_rows(lapply(seq_along(group_terms), function(i) {
    dev <- est_mat[, i] - full[i]
    top <- order(abs(dev), decreasing = TRUE, na.last = TRUE)[1]
    tibble::tibble(
      key = k,
      group = group_labels[i],
      full = full[i],
      loo_min = min(est_mat[, i], na.rm = TRUE),
      loo_max = max(est_mat[, i], na.rm = TRUE),
      top_ego = egos[top],
      top_ego_ties = sum(dd$egoid == egos[top]),
      top_ego_group = unique(dd$ego_rel[dd$egoid == egos[top]]),
      top_shift = dev[top]
    )
  }))
}))

# Print and save ----------------------------------------------------------
cat("\n--- Group coefficients, ego vs two-way SE ---\n"); print(coef_table, n = Inf)
cat("\n--- Contrasts, ego vs two-way p ---\n"); print(contrast_twoway, n = Inf)
cat("\n--- Bootstrap percentile CIs ---\n"); print(boot_ci, n = Inf)
cat("\n--- Leave-one-ego-out ---\n"); print(loo_group, n = Inf)

saveRDS(
  list(cluster_check = cluster_check, coef_table = coef_table, contrast_twoway = contrast_twoway,
       boot_ci = boot_ci, boot_failures = boot_failures, loo_group = loo_group, n_boot = n_boot),
  here("Data", "inference_robustness.RDS")
)

# LaTeX ---------------------------------------------------------------------
fmt_p <- function(p) ifelse(p < 0.001, "$<$0.001", sprintf("%.3f", p))
b_lab <- c(cohort = "Cohort", pool = "Pool")
m_lab <- c(m1 = "Model 1", m3 = "Model 3")

panel_ab <- unlist(lapply(c("m1", "m3"), function(m) {
  c(
    sprintf("\\textit{Panel %s: %s group coefficients (log-odds vs.\\ Catholic)}\\\\[2pt]",
            ifelse(m == "m1", "A", "B"), m_lab[[m]]),
    "\\begin{tabular}{llrrrrrr}", "\\toprule",
    "Baseline & Group & Est. & SE (ego) & SE (two-way) & Boot 95\\% CI & $p$ (ego) & $p$ (two-way) \\\\",
    "\\midrule",
    unlist(lapply(c("cohort", "pool"), function(b) {
      k <- paste(b, m, sep = "_")
      cc <- coef_table[coef_table$key == k, ]
      bc <- boot_ci[boot_ci$key == k, ]
      vapply(seq_along(group_terms), function(i) {
        ci <- bc[bc$contrast == group_labels[i], ]
        sprintf("%s & %s & %.3f & %.3f & %.3f & (%.3f, %.3f) & %s & %s \\\\",
                ifelse(i == 1, b_lab[[b]], ""), group_labels[i], cc$est[i], cc$se_ego[i],
                cc$se_twoway[i], ci$lo, ci$hi, fmt_p(cc$p_ego[i]), fmt_p(cc$p_twoway[i]))
      }, character(1))
    })),
    "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
  )
}))

pair_rows <- unlist(lapply(c("cohort", "pool"), function(b) {
  unlist(lapply(c("m1", "m3"), function(m) {
    k <- paste(b, m, sep = "_")
    vapply(names(contrast_defs)[4:6], function(nm) {
      ct <- contrast_twoway[contrast_twoway$key == k & contrast_twoway$contrast == nm, ]
      ci <- boot_ci[boot_ci$key == k & boot_ci$contrast == nm, ]
      sprintf("%s & %s & %s & %.3f & (%.3f, %.3f) & %s & %s \\\\",
              b_lab[[b]], m_lab[[m]], nm, ct$est, ci$lo, ci$hi, fmt_p(ct$p_ego), fmt_p(ct$p_twoway))
    }, character(1))
  }))
}))

panel_c <- c(
  "\\textit{Panel C: Pairwise non-Catholic contrasts (log-odds difference)}\\\\[2pt]",
  "\\begin{tabular}{llllrrrr}", "\\toprule",
  "Baseline & Model & Contrast & Diff. & Boot 95\\% CI & $p$ (ego) & $p$ (two-way) \\\\",
  "\\midrule",
  pair_rows,
  "\\bottomrule", "\\end{tabular}", "\\\\[8pt]"
)

loo_rows <- unlist(lapply(c("cohort", "pool"), function(b) {
  unlist(lapply(c("m1", "m3"), function(m) {
    k <- paste(b, m, sep = "_")
    lg <- loo_group[loo_group$key == k, ]
    vapply(seq_len(nrow(lg)), function(i) {
      sprintf("%s & %s & %.3f & %.3f to %.3f & %s (%s, %d ties) \\\\",
              paste(b_lab[[b]], m_lab[[m]]), lg$group[i], lg$full[i],
              lg$loo_min[i], lg$loo_max[i], format(lg$top_ego[i]), lg$top_ego_group[i], lg$top_ego_ties[i])
    }, character(1))
  }))
}))

panel_d <- c(
  "\\textit{Panel D: Leave-one-ego-out influence on group coefficients}\\\\[2pt]",
  "\\begin{tabular}{lllll}", "\\toprule",
  "Baseline and model & Group & Full estimate & Range over ego deletions & Most influential ego \\\\",
  "\\midrule",
  loo_rows,
  "\\bottomrule", "\\end{tabular}"
)

tex <- c(
  "\\begin{table}[htbp]",
  "\\caption{\\label{tab:inference-robustness}Inference Robustness for the Pooled Group Coefficients under Both Opportunity Baselines (Waves 3--8).}",
  "\\centering", "\\scriptsize",
  panel_ab, panel_c, panel_d,
  "\\\\[4pt]",
  sprintf("\\begin{minipage}{0.95\\textwidth}\\footnotesize \\textit{Note:} Ego-clustered SEs cluster on egoid; two-way SEs cluster on egoid and alterid. Boot 95\\%% CIs are percentile intervals from %d ego-cluster pairs replicates (egos resampled with replacement within group). Panel D refits the model %d times, dropping one ego at a time; the most influential ego is the one whose removal shifts the coefficient most. With 19 Other Religion egos, these checks indicate sensitivity rather than providing exact inference.\\end{minipage}", n_boot, n_distinct(dd$egoid)),
  "\\end{table}"
)
writeLines(tex, here("Tabs", "tbl-inference-robustness.tex"))
cat("\nTable saved to Tabs/tbl-inference-robustness.tex\n")
