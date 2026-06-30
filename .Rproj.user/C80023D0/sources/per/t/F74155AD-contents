# Header ------------------------------------------------------------------

# Title: create_simulations
# Author: Michael Wood
# Created: 20240603
# Last Edited: 20240603
# Purpose: Create simulated ego-networks using the nethealth data

# NOTE: Run AFTER prep_data20240603


# Load packages -----------------------------------------------------------

library(here)
library(readr)
library(dplyr)



# Create simulated data ---------------------------------------------------


#Set weights equal to the distribution of religious identities derived from random sample
weights <- c(0.73119777, 0.12395543, 0.04596100, 0.09888579)

#Set Seed
set.seed(2019)


#Create simulated_df
df_sim_avg_ei <- as.data.frame(levels(df_w3_comb_data$yourelig_1))
df_sim_avg_ei <- rename(df_sim_avg_ei, "yourelig_1" = "levels(df_w3_comb_data$yourelig_1)")

# Function to create many simulations and aggregate the average EI Indices for each group
get_simulated_ei <- function(data){
  df_simulated <- data
  df_simulated <- df_simulated %>% 
    select(egoid, yourelig_1, alterid, altrelig)
  
  #Set the choices of religious identities
  religions <- c("Catholic", "NoReligion", "OtherReligion", "Protestant")
  
  #Set size equal to the length of the df
  size = nrow(df_simulated)
  
  #Replace altrelig with a weighted random sample
  weighted_sample <- sample(religions, size = size, prob = weights, replace = TRUE)
  df_simulated$altrelig <- weighted_sample
  
  df_simulated <- df_simulated %>% 
    mutate(
      same_relig = case_when(
        yourelig_1 == "Catholic" & altrelig == "Catholic" ~ 1,
        yourelig_1 == "No Religion" & altrelig == "NoReligion" ~ 1,
        yourelig_1 == "Other Religion" & altrelig == "OtherReligion" ~ 1,
        yourelig_1 == "Protestant" & altrelig == "Protestant" ~ 1,
        TRUE ~ 0
      ))
  
  # count the number of same-relig alters
  df_simulated <- df_simulated %>% 
    group_by(egoid) %>% 
    mutate(n_samerelig = sum(same_relig == 1))
  
  #count the degree
  df_simulated <- df_simulated %>%  
    group_by(egoid) %>% 
    mutate(degree = n())
  
  # count the number of diff-relig alters
  df_simulated <- df_simulated %>%  
    group_by(egoid) %>% 
    mutate(n_diffrelig = degree-n_samerelig)
  
  # calculate EI Index
  df_simulated <- df_simulated |> 
    group_by(egoid) |> 
    mutate(ei = (n_diffrelig-n_samerelig)/(degree))
  
  #subset and return
  df_simulated_sub <- df_simulated |> 
    select(egoid, yourelig_1, ei)
  df_simulated_sub <- distinct(df_simulated_sub)
  
  
  df_means <- df_simulated_sub %>%
    group_by(yourelig_1) %>%
    summarise_at(vars(ei), list(name = mean))
#  return(df_means)
  return(df_means[,2])
}

df_sim_avg_ei <- cbind(df_sim_avg_ei, get_simulated_ei(df_w3_comb_data))


for (i in 1:500){
  df_sim_avg_ei <- cbind(df_sim_avg_ei, get_simulated_ei(df_w3_comb_data))
}

saveRDS(df_sim_avg_ei, here('data', 'df_sim_avg_ei_500.RDS'))
