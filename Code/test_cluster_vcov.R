# Header ------------------------------------------------------------------
# Title: test_cluster_vcov
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Unit tests for Code/cluster_vcov.R, as specified in plan
#          WC-AS-v1 (.posit/assistant/plans/2026-10-23-1510-preregistration-
#          alter-stratified.md), Section 8.2 (T1-T6). All tests must pass
#          locally before the full within-cohort run (plan Section 9).
#          Sources cluster_vcov.R into an isolated environment so this
#          script leaves the global environment clean (AGENTS.md,
#          "Testing sourced functions").

library(sandwich)
library(survival)

cv_env <- new.env()
sys.source(here::here("Code", "cluster_vcov.R"), envir = cv_env)

results <- data.frame(test = character(), max_diff = double(), tol = double(),
                       pass = logical(), stringsAsFactors = FALSE)

record <- function(test, max_diff, tol) {
  results[nrow(results) + 1, ] <<- list(test, max_diff, tol, max_diff <= tol)
}

# Shared OLS fixture for T1-T5 ----------------------------------------------
set.seed(9173)
n <- 400
G_ego <- 40
G_alt <- 30
dat <- data.frame(
  ego = sample(seq_len(G_ego), n, replace = TRUE),
  alt = sample(seq_len(G_alt), n, replace = TRUE),
  x1 = rnorm(n),
  x2 = rnorm(n)
)
dat$y <- 1 + 0.5 * dat$x1 - 0.3 * dat$x2 + rnorm(n, sd = 2)

fit <- lm(y ~ x1 + x2, data = dat)
X <- model.matrix(fit)
score <- X * residuals(fit)                    # per-observation score, X_i * e_i
naive_var <- solve(crossprod(X))               # (X'X)^{-1}, the OLS "bread"

# T1: two-way clustering matches sandwich::vcovCL with a data frame of the
# two cluster columns. ------------------------------------------------------
V_two <- cv_env$two_way_vcov(score, naive_var, dat$ego, dat$alt)
V_two_sandwich <- vcovCL(fit, cluster = dat[, c("ego", "alt")], type = "HC0", cadjust = FALSE)
record("T1: two_way_vcov vs vcovCL (two clusters)", max(abs(V_two - V_two_sandwich)), 1e-10)

# T2: one-way clustering matches sandwich::vcovCL with a single cluster. ----
V_one <- cv_env$one_way_vcov(score, naive_var, dat$ego)
V_one_sandwich <- vcovCL(fit, cluster = dat$ego, type = "HC0", cadjust = FALSE)
record("T2: one_way_vcov vs vcovCL (one cluster)", max(abs(V_one - V_one_sandwich)), 1e-10)

# T3: with a singleton second cluster (every row its own alter), two-way
# clustering collapses to one-way clustering by ego. -------------------------
dat$alt_singleton <- seq_len(n)
V_two_singleton <- cv_env$two_way_vcov(score, naive_var, dat$ego, dat$alt_singleton)
record("T3: two_way_vcov with singleton 2nd cluster vs one_way_vcov",
       max(abs(V_two_singleton - V_one)), 1e-10)

# T4: two_way_vcov is symmetric in its two cluster arguments. ----------------
V_two_swapped <- cv_env$two_way_vcov(score, naive_var, dat$alt, dat$ego)
record("T4: two_way_vcov symmetric in cluster arguments",
       max(abs(V_two - V_two_swapped)), 1e-10)

# T5: cluster_meat equals the explicit sum over clusters of U_g %*% t(U_g). --
M_explicit <- matrix(0, ncol(score), ncol(score))
for (g in unique(dat$ego)) {
  U_g <- colSums(score[dat$ego == g, , drop = FALSE])
  M_explicit <- M_explicit + outer(U_g, U_g)
}
M_fn <- cv_env$cluster_meat(score, dat$ego)
record("T5: cluster_meat vs explicit sum over clusters",
       max(abs(M_fn - M_explicit)), 1e-10)

# T6: simulated stratified coxph (Breslow, strata, cluster); one_way_vcov
# built from the score residuals and naive.var equals coxph's own
# cluster-robust vcov. -------------------------------------------------------
set.seed(5209)
G <- 50
n_per <- 6
egoid <- rep(seq_len(G), each = n_per)
n_cox <- length(egoid)
x <- rnorm(n_cox)
strat <- rep(seq_len(n_cox / 2), each = 2)
beta_true <- 0.7
time2 <- rexp(n_cox, rate = exp(beta_true * x))
status <- rep(1, n_cox)
simdat <- data.frame(egoid, x, strat, time2, status)

fit_cox <- coxph(Surv(time2, status) ~ x + strata(strat) + cluster(egoid),
                  data = simdat, ties = "breslow")
score_cox <- as.matrix(residuals(fit_cox, type = "score"))
one_way_cox <- cv_env$one_way_vcov(score_cox, fit_cox$naive.var, simdat$egoid)
record("T6: one_way_vcov vs coxph cluster-robust vcov (simulated)",
       max(abs(one_way_cox - vcov(fit_cox))), 1e-8)

# Additional check implied by plan C3 (not a numbered T-test, but exercises
# min_eigenvalue on a matrix constructed to be positive semidefinite by
# construction, since V_two above is a valid sandwich estimator).
eig_min <- cv_env$min_eigenvalue(V_two)
record("C3 check: min_eigenvalue(V_two) >= -1e-10 (PSD)", max(0, -eig_min), 1e-10)

cat("\ncluster_vcov.R unit tests (plan WC-AS-v1, Section 8.2)\n")
print(results, row.names = FALSE)
cat("\nAll tests pass:", all(results$pass), "\n")

if (!all(results$pass)) {
  stop("One or more cluster_vcov.R unit tests failed. See the table above.")
}
