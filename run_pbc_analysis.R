library(here)
library(readr)
library(dplyr)

# Load and prep data (standardized across sessions)
df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
df_basicsurv <- read_csv('Data/BasicSurvey.csv', show_col_types = FALSE)

df_all_clean <- df_netsurv %>%
  left_join(df_basicsurv, by = "egoid") %>%
  filter(!is.na(yourelig_1), altrelucat == "Student") %>%
  mutate(
    ego_rel = as.character(yourelig_1),
    alt_rel = case_when(altrelig == "NoReligion" ~ "No Religion", altrelig == "OtherReligion" ~ "Other Religion", TRUE ~ altrelig)
  ) %>%
  filter(ego_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant"),
         alt_rel %in% c("Catholic", "No Religion", "Other Religion", "Protestant")) %>%
  filter(as.numeric(gsub("Wave", "", wave)) >= 3)

# Function to compute abcd table for a given ego's religious network
abcd_relig <- function(n, w, attr_name="ego_rel") {
  # Subset to ego n and their ties in the network w
  # For religious homophily:
  # a: tied to same rel
  # b: tied to diff rel
  # c: not tied to same rel
  # d: not tied to diff rel
  
  ego_data <- w %>% filter(egoid == n)
  all_alters <- w %>% filter(egoid != n) %>% pull(alterid) %>% unique()
  
  # For the current wave, we look at the ego's ties
  # (Simulating for simplicity across pooled waves)
  # Actually, the PBC requires knowing all possible ties, which is hard in ego data.
  # We will approximate by using the available alter set
  return(NULL) # Placeholder
}

# The Point Biserial Correlation requires the 2x2 table for *each* ego.
# Let's compute it for the full pooled dyadic data.
# A = number of same-religion ties sent by ego
# B = number of diff-religion ties sent by ego
# C = number of same-religion potential alters NOT tied to ego
# D = number of diff-religion potential alters NOT tied to ego

results <- df_all_clean %>%
  group_by(egoid) %>%
  summarize(
    a = sum(ego_rel == alt_rel),
    b = sum(ego_rel != alt_rel),
    # c and d require knowledge of the full cohort or at least the ego's school
    # Approximating based on pool size for each ego:
    total_same = sum(df_all_clean$ego_rel == unique(ego_rel)), # Simplified
    total_diff = n() - total_same,
    c = total_same - a,
    d = total_diff - b
  ) %>%
  mutate(
    num = (a*d - b*c),
    den = sqrt((a+c)*(b+d)*(a+b)*(c+d)),
    pbc = ifelse(den == 0, 0, num/den)
  )

print(mean(results$pbc, na.rm=TRUE))
