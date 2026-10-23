# Header ------------------------------------------------------------------
# Title: 00_sample_descriptives
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-22
# Purpose: Reproduce the sample descriptives quoted in the Methods section
#          (Section 2) of paper.tex. Ego-level demographics and religion come
#          from the Basic Survey; sample flow and alter characteristics come
#          from the Network Survey. Writes Data/sample_descriptives.csv and
#          checks every value quoted in the manuscript against the computed
#          value, so drift between text and data is flagged.
#
#          Denominators: ego-level percentages use all egos in the Basic
#          Survey (missing responses are reported as their own category);
#          tie-level percentages use the non-family student ties that enter
#          the analysis (Waves 1-8 pooled, as in Code/01 and Code/07).

# Load libraries -----------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(tibble)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here("Data", "NetWorkSurvey.csv"), show_col_types = FALSE)
df_basicsurv <- read_csv(here("Data", "BasicSurvey.csv"), show_col_types = FALSE)

# Helpers -------------------------------------------------------------------
# Distribution of a categorical variable over a fixed set of levels. Missing
# values form their own level. Every observed value must match a listed level,
# so a label mismatch stops the script rather than being silently dropped.
describe_cat <- function(x, section, variable, levels, denom, denom_label) {
  x <- as.character(x)
  x[is.na(x)] <- "Missing"
  stopifnot(all(x %in% levels))
  n <- vapply(levels, function(l) sum(x == l), integer(1))
  tibble(
    section = section, variable = variable, level = levels, n = n,
    pct = 100 * n / denom, denominator = denom, denominator_label = denom_label
  )
}

# Ego-level descriptives (Basic Survey) -------------------------------------
n_egos <- nrow(df_basicsurv)

ego_results <- bind_rows(
  describe_cat(df_basicsurv$yourelig_1, "Ego", "Baseline religion (yourelig_1)",
               c("Catholic", "No Religion", "Other Religion", "Protestant", "Missing"),
               n_egos, "all egos"),
  describe_cat(df_basicsurv$gender_1, "Ego", "Gender (gender_1)",
               c("Female", "Male", "Missing"),
               n_egos, "all egos"),
  describe_cat(df_basicsurv$race_1, "Ego", "Race (race_1)",
               c("White", "Latino/a", "Asian-American", "Foreign Student",
                 "African-American", "Other", "Missing"),
               n_egos, "all egos"),
  describe_cat(df_basicsurv$discussrelig_2, "Ego", "Discussion frequency (discussrelig_2)",
               c("Not at all", "Less than 1-2 times a month", "1-2 times a month",
                 "1-2 times a week", "Three times a week or more", "Missing"),
               n_egos, "all egos")
)

# Sample flow and tie-level descriptives (Network Survey) -------------------
n_nominations <- nrow(df_netsurv)
ties_student <- df_netsurv |> filter(altrelucat == "Student")
ties <- ties_student |> filter(family == FALSE)
n_ties <- nrow(ties)

flow <- tibble(
  section = "Sample flow",
  variable = c("Egos", "Nominations", "Nominations", "Nominations", "Nominations", "Nominations"),
  level = c(
    "Egos in Basic Survey",
    "All nominations (all waves)",
    "Student nominations",
    "Family student nominations removed",
    "Non-family student ties (analytic sample)",
    "Analytic ties with alter religion reported"
  ),
  n = c(
    n_egos, n_nominations, nrow(ties_student), nrow(ties_student) - n_ties,
    n_ties, sum(!is.na(ties$altrelig))
  ),
  pct = c(NA, NA, 100 * nrow(ties_student) / n_nominations, NA, NA, NA),
  denominator = NA_real_,
  denominator_label = NA_character_
)

tie_results <- bind_rows(
  describe_cat(ties$altrelig, "Tie", "Alter religion (altrelig)",
               c("Catholic", "Protestant", "NoReligion", "OtherReligion", "Missing"),
               n_ties, "non-family student ties"),
  describe_cat(ties$altsex, "Tie", "Alter gender (altsex)",
               c("Female", "Male", "Missing"),
               n_ties, "non-family student ties"),
  describe_cat(ties$altwhite, "Tie", "Alter white (altwhite)",
               c("TRUE", "FALSE", "Missing"),
               n_ties, "non-family student ties"),
  describe_cat(ties$roommates, "Tie", "Roommates",
               c("TRUE", "FALSE", "Missing"),
               n_ties, "non-family student ties"),
  describe_cat(ties$samedorm, "Tie", "Same dorm",
               c("TRUE", "FALSE", "Missing"),
               n_ties, "non-family student ties")
)

results <- bind_rows(flow, ego_results, tie_results)
write_csv(results, here("Data", "sample_descriptives.csv"))

# Manuscript values ---------------------------------------------------------
# Every number quoted in Methods Section 2 of paper.tex. measure "pct" compares
# a percentage; "n" compares a count. rule "eq" requires the computed value to
# round to the quoted value at its stated precision; "lt" requires it to fall
# below the quoted bound (for example, "<1%").
manuscript <- tribble(
  ~variable, ~level, ~measure, ~reported, ~rule,
  "Egos", "Egos in Basic Survey", "n", 722, "eq",
  "Baseline religion (yourelig_1)", "Catholic", "pct", 72.7, "eq",
  "Baseline religion (yourelig_1)", "No Religion", "pct", 12.3, "eq",
  "Baseline religion (yourelig_1)", "Protestant", "pct", 9.8, "eq",
  "Baseline religion (yourelig_1)", "Other Religion", "pct", 4.6, "eq",
  "Baseline religion (yourelig_1)", "Missing", "pct", 1, "lt",
  "Gender (gender_1)", "Female", "pct", 51.1, "eq",
  "Gender (gender_1)", "Male", "pct", 47.9, "eq",
  "Race (race_1)", "White", "pct", 65.0, "eq",
  "Race (race_1)", "Latino/a", "pct", 12.3, "eq",
  "Race (race_1)", "Asian-American", "pct", 8.7, "eq",
  "Race (race_1)", "Foreign Student", "pct", 7.1, "eq",
  "Race (race_1)", "African-American", "pct", 5.7, "eq",
  "Race (race_1)", "Other", "pct", 1, "lt",
  "Discussion frequency (discussrelig_2)", "Not at all", "pct", 4.6, "eq",
  "Discussion frequency (discussrelig_2)", "Less than 1-2 times a month", "pct", 11.8, "eq",
  "Discussion frequency (discussrelig_2)", "1-2 times a month", "pct", 31.9, "eq",
  "Discussion frequency (discussrelig_2)", "1-2 times a week", "pct", 27.4, "eq",
  "Discussion frequency (discussrelig_2)", "Three times a week or more", "pct", 12.6, "eq",
  "Nominations", "Student nominations", "pct", 48.6, "eq",
  "Nominations", "Student nominations", "n", 17452, "eq",
  "Nominations", "Family student nominations removed", "n", 312, "eq",
  "Nominations", "Non-family student ties (analytic sample)", "n", 17140, "eq",
  "Alter religion (altrelig)", "Catholic", "pct", 67.4, "eq",
  "Alter religion (altrelig)", "Protestant", "pct", 6.9, "eq",
  "Alter religion (altrelig)", "NoReligion", "pct", 7.2, "eq",
  "Alter religion (altrelig)", "OtherReligion", "pct", 2.3, "eq",
  "Alter religion (altrelig)", "Missing", "pct", 16.2, "eq",
  "Alter gender (altsex)", "Female", "pct", 52.2, "eq",
  "Alter gender (altsex)", "Male", "pct", 47.8, "eq",
  "Alter white (altwhite)", "TRUE", "pct", 77.8, "eq",
  "Alter white (altwhite)", "Missing", "pct", 7.5, "eq",
  "Roommates", "TRUE", "pct", 13.7, "eq",
  "Roommates", "Missing", "pct", 31.2, "eq",
  "Same dorm", "TRUE", "pct", 35.3, "eq",
  "Same dorm", "Missing", "pct", 31.2, "eq"
)

# Compare each quoted value with the computed value -----------------------
checks <- manuscript |>
  left_join(results |> select(variable, level, n, pct), by = c("variable", "level")) |>
  mutate(
    computed = if_else(measure == "n", as.numeric(n), pct),
    match = case_when(
      rule == "lt" ~ computed < reported,
      measure == "n" ~ computed == reported,
      TRUE ~ abs(round(computed, 1) - reported) < 1e-9
    )
  )

cat("\nManuscript values checked:", nrow(checks), "| matches:", sum(checks$match %in% TRUE), "\n")
print(checks |> select(variable, level, reported, computed, match), n = Inf)
if (any(!(checks$match %in% TRUE))) {
  warning("Some values quoted in paper.tex Methods do not match the data; see the 'match' column above.")
}

cat("\nSample descriptives written to Data/sample_descriptives.csv\n")
