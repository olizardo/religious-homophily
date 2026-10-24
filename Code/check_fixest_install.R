# Header ------------------------------------------------------------------
# Title: check_fixest_install
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Confirm that fixest loads under Hoffman2's R 4.2.2 build and that
#          two-way (ego and alter) cluster-robust inference runs on a fixed-effects
#          logit. Synthetic data only; no NetHealth records are read.

# Load libraries -----------------------------------------------------------
suppressPackageStartupMessages(library(fixest))

cat("fixest", as.character(packageVersion("fixest")), "under", R.version.string, "\n")

# Synthetic dyadic data: 100 ego clusters, 80 alter clusters -------------
set.seed(7341)
n <- 2000
d <- data.frame(
  ego = sample(1:100, n, replace = TRUE),
  alt = sample(1:80, n, replace = TRUE),
  x = rnorm(n)
)
d$y <- rbinom(n, 1, plogis(-3 + 0.5 * d$x))

m <- feglm(y ~ x | alt, data = d, family = binomial())
print(summary(m, cluster = ~ ego + alt))
stopifnot(is.finite(coef(m)[["x"]]))
cat("two-way clustering smoke test passed\n")
