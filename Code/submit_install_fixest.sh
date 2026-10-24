#!/bin/bash
#$ -cwd
#$ -j y
#$ -o install_fixest.log
#$ -l h_rt=23:50:00
#$ -l h_data=8G
#$ -pe shared 1

# Installs fixest and its dependencies into the dedicated R 4.2.2 library used by the
# within-cohort jobs (R_LIBS), then runs a short two-way clustering check.
# Remote project root: ~/religious-homophily.

source /u/local/Modules/default/init/bash
module load gcc/10.2.0
module load R/4.2.2

# Skip ~/.Renviron. It puts ~/R/x86_64-pc-linux-gnu-library/4.5 (Rcpp 1.1.2, built for
# R 4.5.1) first on the search path, and R 4.2.2 cannot load that build.
export R_ENVIRON_USER=/dev/null
export R_LIBS="$HOME/R/religious-homophily-lib"
mkdir -p "$R_LIBS"

Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); if (!requireNamespace('fixest', quietly = TRUE)) install.packages('fixest', lib = Sys.getenv('R_LIBS'), dependencies = TRUE); cat('fixest installed:', as.character(packageVersion('fixest')), '\n')"

Rscript Code/check_fixest_install.R
