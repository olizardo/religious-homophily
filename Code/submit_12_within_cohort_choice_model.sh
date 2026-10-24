#!/bin/bash
#$ -cwd
#$ -j y
#$ -o wc-as-v1_20261023_run1.log
#$ -l h_rt=23:50:00
#$ -l h_data=8G
#$ -pe shared 1

# Plan WC-AS-v1 run (Code/12_within_cohort_choice_model.R).
# Remote project root: ~/religious-homophily (Code/, Data/, and the .here root marker).
# R is single-threaded and h_data is per slot, so this job reserves 8G in total.
# Unique -o name per run (plan Section 9). Check the exit status with qacct -j <id>.

source /u/local/Modules/default/init/bash
module load gcc/10.2.0
module load R/4.2.2

# The gcc 10.2.0 build of R 4.2.2 has its own system library, which lacks dplyr and
# tidyr. Missing or outdated packages go into a dedicated library placed first on the
# search path via R_LIBS.
export R_LIBS="$HOME/R/religious-homophily-lib"
mkdir -p "$R_LIBS"
# Ignore ~/.Renviron. It puts an R 4.5.1 library (Rcpp 1.1.2) first on the search path,
# which fails to load under R 4.2.2 (undefined symbol: R_getVarEx). Found 2026-10-23.
export R_ENVIRON_USER=/dev/null

Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); req <- c(dplyr = '1.1.0', tidyr = '1.0.0', here = '1.0.0', survival = '3.0.0'); meets <- function(p) requireNamespace(p, quietly = TRUE) && packageVersion(p) >= req[[p]]; miss <- names(req)[!vapply(names(req), meets, logical(1))]; if (length(miss)) install.packages(miss, lib = Sys.getenv('R_LIBS')); stopifnot(all(vapply(names(req), meets, logical(1))))"

# fixest is optional: S10 is reported as NA if it cannot be loaded.
Rscript -e "cat('fixest available:', requireNamespace('fixest', quietly = TRUE), '\n')"

Rscript -e "R.version.string; .libPaths(); packageVersion('dplyr')"

Rscript Code/12_within_cohort_choice_model.R
