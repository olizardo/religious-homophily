library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(sandwich)
library(lmtest)

rel_colors <- c("Catholic" = "#F8766D", "No Religion" = "#00BFC4", "Other Religion" = "#7CAE00", "Protestant" = "#C77CFF")

# ... Data prep ...
df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
df_basicsurv <- read_csv('Data/BasicSurvey.csv', show_col_types = FALSE)

df_all_clean <- df_netsurv %>%
  left_join(df_basicsurv, by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig),
    same_gender = ifelse(gender_1 == altsex, 1, 0),
    same_race = case_when(race_1 == "White" & altwhite == TRUE ~ 1, race_1 == "African-American" & altblack == TRUE ~ 1, race_1 == "Asian-American" & altasian == TRUE ~ 1, race_1 == "Latino/a" & althisla == TRUE ~ 1, TRUE ~ 0),
    close_num = as.numeric(as.factor(close))
  ) %>%
  filter(ego_rel %in% names(rel_colors), alt_rel %in% names(rel_colors))

# Shared theme without gridlines
theme_clean <- theme_minimal() + theme(
  panel.grid = element_blank(),
  strip.text = element_text(size = 12, face = "bold"),
  legend.position = "none"
)

# Fig 1
wave_alter_props <- df_all_clean %>% 
  filter(!is.na(alt_rel)) %>%
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

# Fig 2
groups <- names(rel_colors)
results_q <- list()
for (w in paste0("Wave", 1:8)) {
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
  scale_x_continuous(breaks = 1:8, labels = paste0("W", 1:8)) +
  scale_color_manual(values = rel_colors) +
  labs(x = "Study Wave", y = "Yule's Q (Homophily)") + theme_clean + ylim(0, 1)
ggsave("Plots/fig-yules-q.png", p_q, width = 10, height = 4)

# Fig 3
coef_results <- list()
for (w in paste0("Wave", 3:8)) {
  df_w <- df_dyads <- df_all_clean %>%
    left_join(wave_alter_props %>% select(wave, alt_rel, prop), by = c("wave", "ego_rel" = "alt_rel")) %>%
    mutate(same_religion = ifelse(ego_rel == alt_rel, 1, 0), opportunity_offset = log(prop / (1 - prop))) %>%
    filter(wave == w)
  m_w <- glm(same_religion ~ ego_rel + same_gender + same_race + roommates + samedorm + close_num, family = binomial, offset = opportunity_offset, data = df_w)
  vcov_w <- vcovCL(m_w, cluster = df_w$egoid)
  se_w <- sqrt(diag(vcov_w))
  cf <- coef(m_w)
  get_est <- function(est, se) data.frame(Coefficient = est, Lower = est - 1.96 * se, Upper = est + 1.96 * se)
  coef_results[[w]] <- bind_rows(
    data.frame(Wave = w, Group = "Catholic", get_est(cf["(Intercept)"], se_w["(Intercept)"])),
    data.frame(Wave = w, Group = "No Religion", get_est(cf["(Intercept)"] + cf["ego_relNo Religion"], se_w["ego_relNo Religion"])),
    data.frame(Wave = w, Group = "Other Religion", get_est(cf["(Intercept)"] + cf["ego_relOther Religion"], se_w["ego_relOther Religion"])),
    data.frame(Wave = w, Group = "Protestant", get_est(cf["(Intercept)"] + cf["ego_relProtestant"], se_w["ego_relProtestant"]))
  )
}
df_coef_plot <- bind_rows(coef_results) %>% mutate(Wave_Num = as.numeric(gsub("Wave", "", Wave)))
p_coef <- ggplot(df_coef_plot, aes(x = Wave_Num, y = Coefficient, color = Group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = Lower, ymax = Upper), width = 0.2, alpha = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", alpha = 0.4) +
  facet_wrap(~ Group, nrow = 1) +
  theme_clean +
  scale_color_manual(values = rel_colors) +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  labs(x = "Study Wave", y = "Active Homophily Coefficient (Log-Odds)")
ggsave("Plots/fig-active-coefs.png", p_coef, width = 10, height = 4)
