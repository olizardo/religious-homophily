# Header ------------------------------------------------------------------
# Title: cluster_vcov
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Base-R implementation of one-way and two-way (Cameron, Gelbach,
#          and Miller 2011) cluster-robust sandwich variance estimators,
#          built from per-observation score contributions and a model's
#          naive (model-based) variance ("bread"). Written for plan
#          WC-AS-v1 (.posit/assistant/plans/2026-10-23-1510-preregistration-
#          alter-stratified.md), Section 8.1, to supply the two-way
#          ego/alter clustered standard errors for the within-cohort
#          conditional-logit models (Section 5.2 of that plan).
#
#          These functions are estimator-agnostic: they take a matrix of
#          per-observation score contributions and a naive variance
#          ("bread") matrix, and compute the meat/sandwich. For `lm`, the
#          score is `model.matrix(fit) * residuals(fit)` and the naive
#          variance is `solve(crossprod(model.matrix(fit)))`. For
#          `coxph`/`clogit`, the score is `residuals(fit, type = "score")`
#          and the naive variance is `fit$naive.var`. See
#          Code/test_cluster_vcov.R for both usages, checked against
#          sandwich::vcovCL (OLS) and coxph's own cluster-robust variance.
#
#          Two-way variance formula (Cameron, Gelbach, and Miller 2011):
#          V_two = V0 (M_a + M_b - M_dyad) V0, where M_a and M_b are the
#          one-way cluster "meat" matrices for clustering dimensions a and
#          b, and M_dyad is the meat matrix for the cluster formed by the
#          intersection (pair) of a and b.

# cluster_meat ---------------------------------------------------------------
# Sum, over clusters g, of U_g %*% t(U_g), where U_g is the column vector of
# cluster-g score totals (summing the per-observation score rows that fall
# in cluster g). Returns a p x p matrix, where p = ncol(score).
cluster_meat <- function(score, cluster) {
  score <- as.matrix(score)
  if (nrow(score) != length(cluster)) {
    stop("cluster_meat: `score` has ", nrow(score), " rows but `cluster` has length ",
         length(cluster), ".")
  }
  cluster <- as.factor(cluster)
  # rowsum() sums score rows within each cluster level, giving a
  # (number of clusters) x p matrix of cluster totals U_g.
  U_g <- rowsum(score, group = cluster)
  # crossprod(U_g) = t(U_g) %*% U_g = sum_g U_g %*% t(U_g), since each row of
  # U_g is one cluster's score total (a p-vector).
  crossprod(U_g)
}

# one_way_vcov ----------------------------------------------------------------
# One-way cluster-robust sandwich variance: naive_var %*% meat %*% naive_var.
one_way_vcov <- function(score, naive_var, cluster) {
  naive_var <- as.matrix(naive_var)
  M <- cluster_meat(score, cluster)
  naive_var %*% M %*% naive_var
}

# two_way_vcov ------------------------------------------------------------
# Two-way (Cameron-Gelbach-Miller 2011) cluster-robust sandwich variance.
# The "dyad" cluster is the interaction (paste) of cluster_a and cluster_b:
# V_two = naive_var %*% (M_a + M_b - M_dyad) %*% naive_var.
two_way_vcov <- function(score, naive_var, cluster_a, cluster_b) {
  naive_var <- as.matrix(naive_var)
  if (length(cluster_a) != length(cluster_b)) {
    stop("two_way_vcov: `cluster_a` and `cluster_b` must have the same length.")
  }
  cluster_dyad <- paste(cluster_a, cluster_b, sep = "___")
  M_a <- cluster_meat(score, cluster_a)
  M_b <- cluster_meat(score, cluster_b)
  M_dyad <- cluster_meat(score, cluster_dyad)
  M <- M_a + M_b - M_dyad
  naive_var %*% M %*% naive_var
}

# min_eigenvalue -----------------------------------------------------------
# Minimum eigenvalue of a (numerically symmetrized) matrix V, for the
# positive-semidefinite check (plan Section 5.4, C3).
min_eigenvalue <- function(V) {
  V <- as.matrix(V)
  V_sym <- (V + t(V)) / 2
  min(eigen(V_sym, symmetric = TRUE, only.values = TRUE)$values)
}
