library(here)
library(readr)
library(dplyr)
library(sandwich)
library(lmtest)

# Load data
df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
df_basicsurv <- read_csv('Data/BasicSurvey.csv', show_col_types = FALSE)

# Standardize and prep
df_all_clean <- df_netsurv %>%
  left_join(df_basicsurv, by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig),
    gender_h = ifelse(gender_1 == altsex, 1, 0),
    race_h = case_when(race_1 == "White" & altwhite == TRUE ~ 1, race_1 == "African-American" & altblack == TRUE ~ 1, race_1 == "Asian-American" & altasian == TRUE ~ 1, race_1 == "Latino/a" & althisla == TRUE ~ 1, TRUE ~ 0),
    close_num = as.numeric(as.factor(close)),
    wave_num = as.numeric(gsub("Wave", "", wave)) - 3
  ) %>%
  filter(ego_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"),
         alt_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"))

# Opportunity offset
wave_alter_props <- df_all_clean %>% group_by(wave, alt_rel) %>% count() %>% group_by(wave) %>% mutate(prop = n / sum(n))
df_dyads <- df_all_clean %>%
  left_join(wave_alter_props %>% select(wave, alt_rel, prop), by = c("wave", "ego_rel" = "alt_rel")) %>%
  mutate(
    same_religion = ifelse(ego_rel == alt_rel, 1, 0),
    opportunity_offset = log(prop / (1 - prop))
  )

# --- MODELS ---
# Need to include ego_rel, gender_1 (ego), race_1 (ego), gender_h, race_h, roommates, samedorm, close_num

# Helper for tables
format_est <- function(est, se, pval) {
  stars <- ifelse(pval < 0.001, "***", ifelse(pval < 0.01, "**", ifelse(pval < 0.05, "*", "")))
  sprintf("%.3f%s (%.3f)", est, stars, se)
}

# 1. Wave 3 Table
df_w3 <- df_dyads %>% filter(wave == "Wave3")
m2 <- glm(same_religion ~ ego_rel + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num, 
          family = binomial, offset = opportunity_offset, data = df_w3)
# Regenerate Table C1 (tbl-wave3-reg.tex) ...

# 2. Pooled/Interaction Table (tbl-pooled-interaction-reg.tex)
m_pooled <- glm(same_religion ~ ego_rel + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num + wave_num, 
                family = binomial, offset = opportunity_offset, data = df_dyads)
m_int <- glm(same_religion ~ ego_rel * wave_num + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num, 
             family = binomial, offset = opportunity_offset, data = df_dyads)

# Re-saving logic here... (Simplified representation of table export)
