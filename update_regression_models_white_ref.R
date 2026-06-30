library(readr)
library(dplyr)
library(sandwich)

# Data prep
df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
df_basicsurv <- read_csv('Data/BasicSurvey.csv', show_col_types = FALSE)

df_dyads <- df_netsurv %>%
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
  mutate(race_1 = relevel(factor(race_1), ref = "White")) %>%
  filter(ego_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"),
         alt_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"))

# Wave 3 Model for Table 1 (Model 3 with all controls)
df_w3 <- df_dyads %>% filter(wave == "Wave3")
wave_props <- df_dyads %>% group_by(wave, alt_rel) %>% count() %>% group_by(wave) %>% mutate(prop = n / sum(n))
df_w3 <- df_w3 %>% left_join(wave_props %>% select(wave, alt_rel, prop), by = c("wave", "ego_rel" = "alt_rel")) %>%
  mutate(same_religion = ifelse(ego_rel == alt_rel, 1, 0), opportunity_offset = log(prop / (1 - prop))) %>%
  mutate(discuss_num = as.numeric(as.factor(discussrelig_2)))

m3 <- glm(same_religion ~ ego_rel + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num + discuss_num, 
          family = binomial, offset = opportunity_offset, data = df_w3)
print(summary(m3))

# Pooled Model for Table 2
df_dyads <- df_dyads %>% left_join(wave_props %>% select(wave, alt_rel, prop), by = c("wave", "ego_rel" = "alt_rel")) %>%
  mutate(same_religion = ifelse(ego_rel == alt_rel, 1, 0), opportunity_offset = log(prop / (1 - prop)))
m_p <- glm(same_religion ~ ego_rel + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num + wave_num, 
           family = binomial, offset = opportunity_offset, data = df_dyads)
print(summary(m_p))
