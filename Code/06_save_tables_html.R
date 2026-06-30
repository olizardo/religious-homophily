# Header ------------------------------------------------------------------
# Title: 06_save_tables_html
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: Compiles all statistical tables generated in this study 
#          (longitudinal, cross-sectional, pooled, interactive, and ERGMs) 
#          and saves them as beautiful, standalone styled HTML files in 
#          the Tabs/ folder for easy viewing and publishing.

library(here)

# Define a function to save a dataframe as a beautiful styled HTML table
save_html_table <- function(df, title, filepath) {
  html_str <- paste0(
    "<!DOCTYPE html>\n<html>\n<head>\n<style>\n",
    "body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; margin: 20px; color: #333; }\n",
    "h2 { color: #1a365d; margin-bottom: 5px; font-size: 1.5em; }\n",
    "p { color: #555; margin-top: 0; margin-bottom: 20px; font-size: 0.95em; }\n",
    "table { border-collapse: collapse; width: 100%; max-width: 1000px; margin-top: 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }\n",
    "th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #e2e8f0; }\n",
    "th { background-color: #2b6cb0; color: white; font-weight: bold; text-transform: uppercase; font-size: 0.85em; letter-spacing: 0.5px; }\n",
    "tr:nth-child(even) { background-color: #f7fafc; }\n",
    "tr:hover { background-color: #edf2f7; }\n",
    "td { font-size: 0.9em; }\n",
    "td.numeric { text-align: center; }\n",
    "th.numeric { text-align: center; }\n",
    "</style>\n</head>\n<body>\n",
    "<h2>", title, "</h2>\n",
    "<p>Generated on ", format(Sys.time(), "%Y-%m-%d"), "</p>\n",
    "<table>\n<thead>\n<tr>\n"
  )
  
  cols <- colnames(df)
  for (col in cols) {
    if (col %in% c("Religious Group", "Predictor", "Group & Metric", "Parameter", "Group")) {
      html_str <- paste0(html_str, "<th>", col, "</th>\n")
    } else {
      html_str <- paste0(html_str, "<th class='numeric'>", col, "</th>\n")
    }
  }
  html_str <- paste0(html_str, "</tr>\n</thead>\n<tbody>\n")
  
  for (i in 1:nrow(df)) {
    html_str <- paste0(html_str, "<tr>\n")
    for (j in 1:ncol(df)) {
      val <- df[i, j]
      col_name <- cols[j]
      if (col_name %in% c("Religious Group", "Predictor", "Group & Metric", "Parameter", "Group")) {
        html_str <- paste0(html_str, "<td>", val, "</td>\n")
      } else {
        html_str <- paste0(html_str, "<td class='numeric'>", val, "</td>\n")
      }
    }
    html_str <- paste0(html_str, "</tr>\n")
  }
  
  html_str <- paste0(html_str, "</tbody>\n</table>\n</body>\n</html>")
  writeLines(html_str, filepath)
}

# Construct Table A1: Yule's Q Longitudinal Trajectory
df_a1 <- data.frame(
  `Religious Group` = c("Catholic", "No Religion", "Other Religion", "Protestant"),
  W1 = c("0.422", "0.833", "0.726", "0.352"),
  W2 = c("0.310", "0.530", "0.794", "0.414"),
  W3 = c("0.274", "0.454", "0.833", "0.430"),
  W4 = c("0.400", "0.632", "0.752", "0.526"),
  W5 = c("0.454", "0.572", "0.744", "0.441"),
  W6 = c("0.516", "0.647", "0.797", "0.381"),
  W7 = c("0.466", "0.460", "0.876", "0.577"),
  W8 = c("0.478", "0.608", "0.833", "0.438"),
  check.names = FALSE, stringsAsFactors = FALSE
)

# Construct Table B1: Opportunity Structure Diagnostics
df_b1 <- data.frame(
  `Group & Metric` = c(
    "Catholic Proportion (p)", "Catholic Opportunity Offset",
    "No Religion Proportion (p)", "No Religion Opportunity Offset",
    "Other Religion Proportion (p)", "Other Religion Opportunity Offset",
    "Protestant Proportion (p)", "Protestant Opportunity Offset"
  ),
  Wave3 = c("0.818", "+1.503", "0.074", "-2.533", "0.024", "-3.697", "0.084", "-2.389"),
  Wave4 = c("0.820", "+1.516", "0.069", "-2.599", "0.030", "-3.493", "0.081", "-2.423"),
  Wave5 = c("0.783", "+1.284", "0.092", "-2.286", "0.032", "-3.411", "0.093", "-2.274"),
  Wave6 = c("0.794", "+1.349", "0.103", "-2.164", "0.024", "-3.697", "0.078", "-2.470"),
  Wave7 = c("0.775", "+1.237", "0.103", "-2.165", "0.020", "-3.918", "0.103", "-2.165"),
  Wave8 = c("0.793", "+1.343", "0.108", "-2.111", "0.022", "-3.797", "0.077", "-2.478"),
  Mean = c("0.797", "+1.372", "0.091", "-2.310", "0.025", "-3.652", "0.086", "-2.367"),
  check.names = FALSE, stringsAsFactors = FALSE
)

# Construct Table C1: Nested Dyadic Wave 3 Regressions
df_c1 <- data.frame(
  Predictor = c(
    "Intercept (Catholic Baseline)", "Protestant (Ego)", "No Religion (Ego)", "Other Religion (Ego)",
    "Same Gender", "Same Race", "Roommates (TRUE)", "Same Dorm (TRUE)", "Religious Discussion",
    "Observations (N)", "Residual Deviance", "AIC"
  ),
  `Model 1 (Baseline)` = c("0.148* (0.069)", "0.631** (0.193)", "0.698*** (0.210)", "2.044*** (0.356)", "—", "—", "—", "—", "—", "2,024", "1,790.0", "1,798.0"),
  `Model 2 (+ Structural)` = c("0.217 (0.163)", "0.596** (0.199)", "0.167 (0.267)", "2.079*** (0.360)", "0.067 (0.196)", "0.188 (0.136)", "-0.218 (0.170)", "-0.286 (0.184)", "—", "1,933", "1,640.5", "1,656.5"),
  `Model 3 (+ Salience)` = c("0.299 (0.304)", "0.585** (0.200)", "0.148 (0.269)", "2.064*** (0.361)", "0.074 (0.199)", "0.175 (0.139)", "-0.242 (0.171)", "-0.317&dagger; (0.186)", "-0.013 (0.068)", "1,906", "1,609.6", "1,627.6"),
  check.names = FALSE, stringsAsFactors = FALSE
)

# Construct Table C2: Pooled Models (Full vs Intimate)
df_c2 <- data.frame(
  Predictor = c(
    "Intercept (Catholic Baseline)", "Protestant (Ego)", "No Religion (Ego)", "Other Religion (Ego)",
    "Same Gender", "Same Race", "Roommates (TRUE)", "Same Dorm (TRUE)", "Longitudinal Trend (wave_num)",
    "Observations (N)", "Unique Egos"
  ),
  `Full Pooled Model` = c("0.167 (0.123)", "0.530** (0.186)", "0.585** (0.197)", "1.785*** (0.526)", "0.117 (0.135)", "0.268* (0.118)", "-0.149 (0.105)", "-0.266* (0.124)", "0.018 (0.026)", "9,790", "441"),
  `Intimate Ties Model` = c("0.093 (0.174)", "0.715** (0.269)", "0.279 (0.354)", "0.946&dagger; (0.567)", "0.229 (0.171)", "0.284* (0.135)", "-0.053 (0.127)", "-0.345* (0.157)", "0.001 (0.032)", "5,523", "364"),
  check.names = FALSE, stringsAsFactors = FALSE
)

# Construct Table C3: Interaction Model
df_c3 <- data.frame(
  Parameter = c(
    "Intercept (Catholic Baseline)", "Protestant (Ego)", "No Religion (Ego)", "Other Religion (Ego)",
    "Longitudinal Trend (wave_num)", "Same Gender", "Same Race", "Roommates (TRUE)", "Same Dorm (TRUE)",
    "Protestant x wave_num", "No Religion x wave_num", "Other Religion x wave_num"
  ),
  `Coefficient (Beta)` = c("0.129", "0.637", "0.385", "1.720", "0.018", "0.111", "0.265", "-0.150", "-0.257", "-0.048", "0.085", "0.029"),
  `Clustered S.E.` = c("0.141", "0.231", "0.227", "0.557", "0.026", "0.134", "0.118", "0.105", "0.124", "0.071", "0.078", "0.108"),
  `z-value` = c("0.912", "2.753", "1.691", "3.086", "0.704", "0.829", "2.249", "-1.435", "-2.071", "-0.682", "1.077", "0.268"),
  `p-value` = c("0.362", "0.006", "0.091", "0.002", "0.481", "0.407", "0.025", "0.151", "0.038", "0.495", "0.281", "0.789"),
  Significance = c("", "**", "&dagger;", "**", "", "", "*", "", "*", "", "", ""),
  check.names = FALSE, stringsAsFactors = FALSE
)

# Construct Table C4: ERGM Results
df_c4 <- data.frame(
  Parameter = c(
    "Baseline Density (edges)", "Reciprocity (mutual)", "Popularity Dispersion (gwidegree)",
    "Activity Dispersion (gwodegree)", "Transitivity (gwnsp)", "Same Gender", "Same Race",
    "Catholic Match", "No Religion Match", "Protestant Match", "Other Religion Match"
  ),
  `Model A (Baseline)` = c("-6.855***", "5.336***", "—", "—", "—", "0.799***", "0.230***", "-0.037", "0.412&dagger;", "0.195", "-Inf (fixed)"),
  `Model B (Structural Control)` = c("-5.152***", "6.957***", "0.863***", "-2.898***", "-0.590***", "0.796***", "0.243***", "-0.036", "0.404", "0.199", "-Inf (fixed)"),
  check.names = FALSE, stringsAsFactors = FALSE
)

# Save all as beautiful HTML tables
save_html_table(df_a1, "Table A1: Longitudinal Trajectory of Religious Homophily (Yule's Q)", here("Tabs", "Table_A1_Yules_Q.html"))
save_html_table(df_b1, "Table B1: Opportunity Structure Diagnostics", here("Tabs", "Table_B1_Opportunity_Structure.html"))
save_html_table(df_c1, "Table C1: Nested Dyadic Wave 3 Regressions", here("Tabs", "Table_C1_Wave3_Regressions.html"))
save_html_table(df_c2, "Table C2: Pooled Models (Full vs Intimate)", here("Tabs", "Table_C2_Pooled_Regressions.html"))
save_html_table(df_c3, "Table C3: Interactive Dyadic Model Results", here("Tabs", "Table_C3_Interaction_Regression.html"))
save_html_table(df_c4, "Table C4: Exponential Random Graph Model (ERGM) Results", here("Tabs", "Table_C4_ERGM_Results.html"))

cat("All HTML tables successfully saved to the Tabs/ folder.\n")
