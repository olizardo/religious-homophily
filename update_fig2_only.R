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

groups <- names(rel_colors)
results_q <- list()
for (w in paste0("Wave", 3:8)) {
  df_w <- df_all_clean %>% filter(wave == w)
  m <- matrix(0, nrow = 4, ncol = 4, dimnames = list(groups, groups))
  counts <- df_w %>% filter(ego_rel %in% groups, alt_rel %in% groups) %>% count(ego_rel, alt_rel)
  for (i in 1:nrow(counts)) m[counts$ego_rel[i], counts$alt_rel[i]] <- counts$n[i]
  for (g in groups) {
    a <- m[g, g]; b <- sum(m[g, setdiff(groups, g)]); c <- sum(m[setdiff(groups, g), g]); d <- sum(m[setdiff(groups, g), setdiff(groups, g)])
    q <- if((a * d + b * c) == 0) 0 else (a * d - b * c) / (a * d + b * c)
    results_q[[length(results_q)+1]] <- data.frame(Wave = w, Group = g, Yules_Q = q)
  }
}
df_q_waves <- bind_rows(results_q) %>% mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))
p_q <- ggplot(df_q_waves, aes(x = Wave_Num, y = Yules_Q, color = Group)) +
  geom_line(linewidth = 1.2) + geom_point(size = 3) +
  facet_wrap(~ Group, nrow = 1) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  scale_color_manual(values = rel_colors) +
  labs(x = "Study Wave", y = "Yule's Q (Homophily)") + theme_clean + ylim(0, 1)
ggsave("Plots/fig-yules-q.png", p_q, width = 10, height = 4)
