
# Header ------------------------------------------------------------------

# Title: egonet_relig_models
# Author: Michael Wood
# Created: 20220915
# Last Edited: 20220915
# Purpose: Prepare survey and ego-network data for (W3) analysis


# Preliminaries -----------------------------------------------------------

library(here)
library(dplyr)
library(broom)
library(ggplot2)
library(ggfortify)


# Subset the data ---------------------------------------------------------

df_w3_comb_data <- df_w3_comb_data |> 
  select(egoid, yourelig_1, degree, n_norelig, perc_none, gender_1, 
         perc_samegender, cc, ei)

df_w3_comb_data <- distinct(df_w3_comb_data)  



hist(df_w3_comb_data$ei)

model <- lm(ei ~ yourelig_1 + degree, df_w3_comb_data)
summary(model)

model.diag.metrics <- augment(model)
head(model.diag.metrics)

ggplot(model.diag.metrics, aes(yourelig_1, ei)) +
  geom_point() +
  stat_smooth(method = lm, se = FALSE) +
  geom_segment(aes(xend = yourelig_1, yend = .fitted), color = "red", size = 0.3)

autoplot(model)

df_w3_comb_data <- df_w3_comb_data |> 
  filter(!is.na(cc))

model <- lm(cc ~ yourelig_1 + degree, df_w3_comb_data)
summary(model)

model_glm <- glm(cc ~ yourelig_1 + degree,
                 data = df_w3_comb_data,
                 family = binomial)
summary(model_glm)

se_glm_robust = coeftest(model_glm, vcov = vcovHC(model_glm, type="HC"))
se_glm_robust


model <- lm(perc_none ~ yourelig_1 + degree, df_w3_comb_data)
summary(model)

model_glm <- glm(perc_none ~ yourelig_1 + degree,
                 data = df_w3_comb_data,
                 family = binomial)
summary(model_glm)

library(lmtest)
library(sandwich)

se_glm_robust = coeftest(model_glm, vcov = vcovHC(model_glm, type="HC"))
se_glm_robust



model <- lm(degree ~ yourelig_1, df_w3_comb_data)
summary(model)


install.packages('egor')
