# Header ------------------------------------------------------------------

# Title: regression_ei_norm
# Author: Michael Wood
# Created: 20240603
# Last Edited: 20240603
# Purpose: Create statistical models predicting normalized ei

# Note: Run prep_data.20240603.R BEFORE running

# Preliminaries -----------------------------------------------------------

library(here)
library(dplyr)
library(jtools)

# jtools requires the following packages:
#install.packages("huxtable")
#install.packages("sandwich")

# jtool uses these packages to export to a word doc:
#install.packages("officer")
#install.packages("flextable")

# Regression Models -------------------------------------------------------

model_ei_norm <- lm(ei_norm ~ yourelig_1 + degree + gender_1, df_w3_model_data)

model_ei <- lm(ei ~ yourelig_1 + degree + gender_1, df_w3_model_data)

export_summs(model_ei, model_ei_norm,
             model.names = c("Model 1: EI", "Model 2: Normalized EI"),
             coefs = c(
               "Religious Identity: None" = "yourelig_1No Religion",
               "Religious Identity: Other" = "yourelig_1Other Religion",
               "Religious Identity: Protestant" = "yourelig_1Protestant",
               "Degree" = "degree",
               "Men" = "gender_1Male"),
             robust = "HC1")
