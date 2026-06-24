# Header ------------------------------------------------------------------

# Title: summary_stats
# Author: Michael Wood
# Created: 20240604
# Last Edited: 20240604
# Purpose: displays summary statistics for key variables

# Note: Run prep_data.20240603.R BEFORE running


# Sample Statistics -------------------------------------------------------

#ego religion
table(df_w3_model_data$yourelig_1)
round(100*prop.table(table(df_w3_model_data$yourelig_1)),2)

#ego gender
table(df_w3_model_data$gender_1)
round(100*prop.table(table(df_w3_model_data$gender_1)),2)

#alter religion
table(df_w3_comb_data$altrelig)
round(100*prop.table(table(df_w3_comb_data$altrelig)),2)

#alter gender
table(df_w3_comb_data$altsex)
round(100*prop.table(table(df_w3_comb_data$altsex)),2)

#EI
round(mean(df_w3_model_data$ei),4)
round(sd(df_w3_model_data$ei),4)
hist(df_w3_model_data$ei)

#Normalized EI
round(mean(df_w3_model_data$ei_norm),4)
round(sd(df_w3_model_data$ei_norm),4)
hist(df_w3_model_data$ei_norm)

#Mean ego degree
summary(df_w3_model_data$degree)
round(sd(df_w3_model_data$degree),4)

#EI by religious identity
df_w3_model_data %>%
  group_by(yourelig_1) %>%
  summarise_at(vars(ei), list(mean = mean, sd = sd))

#Normalized EI by religious identity
df_w3_model_data %>%
  group_by(yourelig_1) %>%
  summarise_at(vars(ei_norm), list(mean = mean, sd = sd))
     