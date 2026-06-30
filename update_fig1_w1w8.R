library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(scales)

df_all_clean <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE) %>%
  left_join(read_csv('Data/BasicSurvey.csv', show_col_types = FALSE), by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(ego_rel = as.character(yourelig_1),
         alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig))

# Fig 1: Update breaks and labels to W1-W8
wave_alter_props <- df_all_clean %>% 
  filter(!is.na(alt_rel)) %>%
  group_by(wave, alt_rel) %>% count() %>% group_by(wave) %>% 
  mutate(prop = n / sum(n), Wave_Num = as.numeric(gsub("Wave", "", wave)))

p_opp <- ggplot(wave_alter_props, aes(x = Wave_Num, y = prop)) +
  geom_line(aes(color = alt_rel), linewidth = 1.2) + geom_point(aes(color = alt_rel), size = 3) +
  facet_wrap(~ alt_rel, nrow = 1) +
  scale_x_continuous(breaks = 1:8, labels = paste0("W", 1:8)) +
  scale_y_continuous(labels = percent, limits = c(0, 1)) +
  scale_color_manual(values = c("Catholic" = "#F8766D", "No Religion" = "#00BFC4", "Other Religion" = "#7CAE00", "Protestant" = "#C77CFF")) +
  labs(x = "Study Wave", y = "Proportion of Alter Pool") + theme_minimal() +
  theme(panel.grid = element_blank(), strip.text = element_text(size = 12, face = "bold"), legend.position = "none")

ggsave("Plots/fig-opportunity-stability.png", p_opp, width = 10, height = 4)
