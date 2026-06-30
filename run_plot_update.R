library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(sandwich)
library(lmtest)

# Load data (assuming the environment is set up)
df_pooled_clean <- read_csv("Data/NetWorkSurvey.csv") # Actually I need the prepared df_pooled_clean from analysis.qmd environment
# Since I cannot easily access the in-memory R state from python, 
# I will just run the script portion that creates the plot.
