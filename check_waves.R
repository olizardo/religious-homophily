library(readr)
library(dplyr)
df_netsurv <- read_csv('Data/NetWorkSurvey.csv', show_col_types = FALSE)
print(unique(df_netsurv$wave))
