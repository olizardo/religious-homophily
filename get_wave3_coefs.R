library(readr)
library(dplyr)
library(sandwich)

df_dyads <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE) %>%
  left_join(read_csv('Data/BasicSurvey.csv', show_col_types = FALSE), by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig),
    gender_h = ifelse(gender_1 == altsex, 1, 0),
    race_h = case_when(race_1 == "White" & altwhite == TRUE ~ 1, race_1 == "African-American" & altblack == TRUE ~ 1, race_1 == "Asian-American" & altasian == TRUE ~ 1, race_1 == "Latino/a" & althisla == TRUE ~ 1, TRUE ~ 0),
    close_num = as.numeric(as.factor(close))
  ) %>%
  filter(ego_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"),
         alt_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"))

wave_props <- df_dyads %>% group_by(wave, alt_rel) %>% count() %>% group_by(wave) %>% mutate(prop = n / sum(n))
df_w3 <- df_dyads %>% filter(wave == "Wave3") %>% 
  left_join(wave_props %>% select(wave, alt_rel, prop), by = c("wave", "ego_rel" = "alt_rel")) %>%
  mutate(same_religion = ifelse(ego_rel == alt_rel, 1, 0), opportunity_offset = log(prop / (1 - prop)))

# Models
m1 <- glm(same_religion ~ ego_rel, family = binomial, offset = opportunity_offset, data = df_w3)
m2 <- glm(same_religion ~ ego_rel + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num, 
          family = binomial, offset = opportunity_offset, data = df_w3)
# Religious salience proxy (discussrelig_2)
df_w3 <- df_w3 %>% mutate(discuss_num = as.numeric(as.factor(discussrelig_2)))
m3 <- glm(same_religion ~ ego_rel + gender_1 + race_1 + gender_h + race_h + roommates + samedorm + close_num + discuss_num, 
          family = binomial, offset = opportunity_offset, data = df_w3)

summary(m1)
summary(m2)
summary(m3)
