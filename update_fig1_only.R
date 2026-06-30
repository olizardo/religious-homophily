library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(scales)

rel_colors <- c("Catholic" = "#F8766D", "No Religion" = "#00BFC4", "Other Religion" = "#7CAE00", "Protestant" = "#C77CFF")

df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
df_basicsurv <- read_csv('Data/BasicSurvey.csv', show_col_types = FALSE)

df_all_clean <- df_netsurv %>%
  left_join(df_basicsurv, by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig)
  ) %>%
  filter(ego_rel %in% names(rel_colors), alt_rel %in% names(rel_colors)) %>%
  filter(as.numeric(gsub("Wave", "", wave)) >= 3) 

theme_clean <- theme_minimal() + theme(
  panel.grid = element_blank(),
  strip.text = element_text(size = 12, face = "bold"),
  legend.position = "none"
)

# Fig 1 (W3-W8 only)
wave_alter_props <- df_all_clean %>% 
  group_by(wave, alt_rel) %>% count() %>% group_by(wave) %>% 
  mutate(prop = n / sum(n), Wave_Num = as.numeric(gsub("Wave", "", wave)))

p_opp <- ggplot(wave_alter_props, aes(x = Wave_Num, y = prop)) +
  geom_line(aes(color = alt_rel), linewidth = 1.2) + geom_point(aes(color = alt_rel), size = 3) +
  facet_wrap(~ alt_rel, nrow = 1) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  scale_y_continuous(labels = percent, limits = c(0, 1)) +
  scale_color_manual(values = rel_colors) +
  labs(x = "Study Wave", y = "Proportion of Alter Pool") + theme_clean
ggsave("Plots/fig-opportunity-stability.png", p_opp, width = 10, height = 4)
