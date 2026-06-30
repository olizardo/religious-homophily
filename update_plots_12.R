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

# Fig 1
wave_alter_props <- df_all_clean %>% group_by(wave, alt_rel) %>% count() %>% group_by(wave) %>% mutate(prop = n / sum(n), Wave_Num = as.numeric(gsub("Wave", "", wave)))
p_opp <- ggplot(wave_alter_props, aes(x = Wave_Num, y = prop, color = alt_rel, group = alt_rel)) +
  geom_line(linewidth = 1.2) + geom_point(size = 3) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  scale_y_continuous(labels = percent, limits = c(0, 1)) +
  labs(x = "Study Wave", y = "Proportion of Alter Pool", color = NULL) + theme_minimal()
ggsave("Plots/fig-opportunity-stability.png", p_opp, width = 7, height = 5)

# Fig 2
results_q <- list()
for (w in paste0("Wave", 1:8)) {
  df_w <- df_all_clean %>% filter(wave == w)
  groups <- c("Catholic", "No Religion", "Other Religion", "Protestant")
  m <- matrix(0, nrow = 4, ncol = 4, dimnames = list(groups, groups))
  counts <- df_w %>% count(ego_rel, alt_rel)
  for (i in 1:nrow(counts)) m[counts$ego_rel[i], counts$alt_rel[i]] <- counts$n[i]
  for (g in groups) {
    a <- m[g, g]; b <- sum(m[g, setdiff(groups, g)]); c <- sum(m[setdiff(groups, g), g]); d <- sum(m[setdiff(groups, g), setdiff(groups, g)])
    q <- (a * d - b * c) / (a * d + b * c)
    results_q[[length(results_q)+1]] <- data.frame(Wave = w, Group = g, Yules_Q = q)
  }
}
df_q_waves <- bind_rows(results_q) %>% mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))
p_q <- ggplot(df_q_waves, aes(x = Wave_Num, y = Yules_Q, color = Group, group = Group)) +
  geom_line(linewidth = 1.2) + geom_point(size = 3) +
  scale_x_continuous(breaks = 1:8, labels = paste0("W", 1:8)) +
  labs(x = "Study Wave", y = "Yule's Q (Homophily)", color = NULL) + theme_minimal() + ylim(0, 1)
ggsave("Plots/fig-yules-q.png", p_q, width = 7, height = 5)
