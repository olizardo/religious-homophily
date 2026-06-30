library(readr)
library(dplyr)

df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
df_basicsurv <- read_csv('Data/BasicSurvey.csv', show_col_types = FALSE)

df_all <- df_netsurv %>%
  left_join(df_basicsurv, by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(ego_rel = as.character(yourelig_1),
         alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig)) %>%
  filter(ego_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"),
         alt_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"))

# Calculate pool sizes for the entire cohort
pool_sizes <- df_all %>% group_by(alt_rel) %>% summarise(pool_count = n())
total_pool <- sum(pool_sizes$pool_count)

# Compute 2x2 table for each ego
results <- df_all %>%
  group_by(egoid, ego_rel) %>%
  summarize(
    a = sum(ego_rel == alt_rel),
    b = sum(ego_rel != alt_rel),
    .groups = 'drop'
  ) %>%
  left_join(pool_sizes, by = c("ego_rel" = "alt_rel")) %>%
  mutate(
    # Pool for 'same' is pool_count
    # Pool for 'diff' is total_pool - pool_count
    c = pool_count - a,
    d = (total_pool - pool_count) - b
  ) %>%
  mutate(
    num = (a*d - b*c),
    den = sqrt(as.numeric(a+c) * as.numeric(b+d) * as.numeric(a+b) * as.numeric(c+d)),
    pbc = ifelse(den == 0, 0, num/den)
  )

print(summary(results$pbc))
