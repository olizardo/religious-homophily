# Header ------------------------------------------------------------------

# Title: Prep_data
# Author: Michael Wood
# Created: 20220908
# Last Edited: 20240603
# Purpose: Prepare survey and ego-network data for (W3) analysis


# Load packages -----------------------------------------------------------

library(here)
library(readr)
library(dplyr)


# Load data ---------------------------------------------------------------

# load ego network survey
df_netsurv <- read_csv(here('data', 'NetWorkSurvey(2-28-20).csv'))

# load basic survey
df_basicsurv <- read_csv(here('data', 'BasicSurvey(3-6-20).csv'))

# Subset Data -------------------------------------------------------------

# subset the network dataframes to W3
df_netsurv <- df_netsurv |> 
  filter(wave == 'Wave3')

# Merge data frames -------------------------------------------------------

df_w3_comb_data <- left_join(df_basicsurv, df_netsurv, by = 'egoid')

#netsurv_id_list <- unique(df_netsurv$egoid)
#basicsurv_id_list <- unique(df_basicsurv$egoid)
#comb_id_list <- Reduce(intersect,list(netsurv_id_list,basicsurv_id_list))

# Filter/Subset Data -------------------------------------------------------------

# filter out yourelig == NA
df_w3_comb_data <- df_w3_comb_data |> 
  filter(!is.na(yourelig_1))

# subset to on-campus ties
df_w3_comb_data <- df_w3_comb_data %>% 
  filter(altrelucat=="Student")

# impute missing alter relig in cases where
# 1) the alter was reported by multiple egos
# 2) at least one ego attributed a relig to that alter
# 3) only one other relig was attributed to that alter
# This preserves 108 ties from being deleted
df_w3_comb_data <- df_w3_comb_data %>% 
  mutate(dupe_alter=
           duplicated(df_w3_comb_data["alterid"]))

df_alter_dupes <- df_w3_comb_data %>% 
  filter(dupe_alter == TRUE)

list_alter_dupes <- unique(df_alter_dupes$alterid)

df_alter_dupes <- df_w3_comb_data %>% 
  filter(alterid %in% list_alter_dupes)

df_alter_dupes <- df_alter_dupes %>%
  group_by(alterid) %>%
  mutate(n_rels = n_distinct(altrelig))

df_alter_dupes <- df_alter_dupes %>% 
  filter(n_rels == 2)

list_na_alter <- df_alter_dupes %>% 
  filter(is.na(altrelig))

list_na_alter <- list_na_alter$alterid

df_alter_dupes <- df_alter_dupes %>%
  filter(alterid %in% list_na_alter)

df_alter_dupes <- df_alter_dupes %>% 
  group_by(alterid) %>%
  mutate(altrelig = unique(altrelig[!is.na(altrelig)]))

df_imputed_alts <- df_alter_dupes %>%
  select(alterid, altrelig)

df_imputed_alts <- distinct(df_imputed_alts)

df_imputed_alts <- rename(df_imputed_alts, altrelig_i = altrelig)

df_w3_comb_data <- left_join(df_w3_comb_data, df_imputed_alts, by = "alterid")

df_w3_comb_data$altrelig <- ifelse(is.na(df_w3_comb_data$altrelig), df_w3_comb_data$altrelig_i, df_w3_comb_data$altrelig)

rm(df_imputed_alts, df_alter_dupes, list_alter_dupes, list_na_alter)


# filter out altrelig == NA
df_w3_comb_data <- df_w3_comb_data |> 
  filter(!is.na(altrelig))

#change yourelig_1 to factor
df_w3_comb_data$yourelig_1 <- as.factor(df_w3_comb_data$yourelig_1)


# Create Proportion Measures ----------------------------------------------

# create same-relig variable
df_w3_comb_data <- df_w3_comb_data |> 
  mutate(
    same_relig = case_when(
      yourelig_1 == "Catholic" & altrelig == "Catholic" ~ 1,
      yourelig_1 == "No Religion" & altrelig == "NoReligion" ~ 1,
      yourelig_1 == "Other Religion" & altrelig == "OtherReligion" ~ 1,
      yourelig_1 == "Protestant" & altrelig == "Protestant" ~ 1,
      TRUE ~ 0
    ))

# count the number of same-relig alters
df_w3_comb_data <- df_w3_comb_data |> 
  group_by(egoid) %>% 
  mutate(n_samerelig = sum(same_relig == 1))

#count the degree
df_w3_comb_data <- df_w3_comb_data |> 
  group_by(egoid) %>% 
  mutate(degree = n())

# count the number of diff-relig alters
df_w3_comb_data <- df_w3_comb_data |> 
  group_by(egoid) %>% 
  mutate(n_diffrelig = degree-n_samerelig)

# calculate EI Index
df_w3_comb_data <- df_w3_comb_data |> 
  group_by(egoid) |> 
  mutate(ei = (n_diffrelig-n_samerelig)/(degree))


# Calculate Normalized EI Indices -----------------------------------------


#create vars for the denominators
table(df_basicsurv$yourelig_1)
e_cath <- 89+33+71
i_cath <- 525-1
e_none <- 525+33+71
i_none <- 89-1
e_other<- 525+89+71
i_other<- 33-1
e_prot <- 525+89+33
i_prot <- 71-1

df_w3_comb_data <- df_w3_comb_data %>% 
  mutate(
    e_denominator = case_when(
      yourelig_1 == "Catholic" ~ e_cath,
      yourelig_1 == "No Religion" ~ e_none,
      yourelig_1 == "Other Religion" ~ e_other,
      yourelig_1 == "Protestant" ~ e_prot,
      TRUE ~ 0
    ))

df_w3_comb_data <- df_w3_comb_data %>% 
  mutate(
    i_denominator = case_when(
      yourelig_1 == "Catholic" ~ i_cath,
      yourelig_1 == "No Religion" ~ i_none,
      yourelig_1 == "Other Religion" ~ i_other,
      yourelig_1 == "Protestant" ~ i_prot,
      TRUE ~ 0
    ))

# calculate normalized EI Index
df_w3_comb_data <- df_w3_comb_data |> 
  group_by(egoid) |> 
  mutate(ei_norm = 
           ((n_diffrelig/e_denominator)-(n_samerelig/i_denominator))/((n_diffrelig/e_denominator)+(n_samerelig/i_denominator)))


# Create subset for regression models -------------------------------------

df_w3_model_data <- df_w3_comb_data |> 
  select(egoid, yourelig_1, degree, ei, ei_norm, n_samerelig, gender_1, race_1)

df_w3_model_data <- distinct(df_w3_model_data)


# Create a df for comparing observed avg ei to simulated networks ---------

df_observed_avg_ei <- df_w3_model_data %>%
  group_by(yourelig_1) %>%
  summarise_at(vars(ei), list(name = mean))
df_observed_avg_ei <-  rename(df_observed_avg_ei, percent = name)
