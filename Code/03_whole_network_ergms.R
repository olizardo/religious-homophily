# Header ------------------------------------------------------------------
# Title: 03_whole_network_ergms
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-06-23
# Purpose: This script structures the within-cohort friendship network 
#          for Wave 3 and provides the Exponential Random Graph Model (ERGM) 
#          specification. This represents the gold standard for controlling 
#          endogenous network structures (reciprocity, transitivity) alongside 
#          religious homophily.
#
# Note: This script requires the 'network' and 'ergm' (statnet) packages.
#       Install them using: install.packages(c("network", "ergm"))

# Load libraries -----------------------------------------------------------
cat("Checking and loading packages...\n")
if (!requireNamespace("network", quietly = TRUE) || !requireNamespace("ergm", quietly = TRUE)) {
  stop("The 'network' or 'ergm' package is not installed. Please install them to run this whole-network analysis.")
}

library(network)
library(ergm)
library(here)
library(readr)
library(dplyr)

# Load data ---------------------------------------------------------------
df_netsurv <- read_csv(here('Data', 'NetWorkSurvey(2-28-20).csv'))
df_basicsurv <- read_csv(here('Data', 'BasicSurvey(3-6-20).csv'))

# 1. Filter to Wave 3 and within-cohort student-to-student ties -----------
# To fit an ERGM, we require a closed, bounded network. We restrict the 
# network to Wave 3 student nominations where both the nominator (ego) 
# and the nominee (alter) are surveyed respondents in our BasicSurvey.

egos_list <- unique(df_basicsurv$egoid)

df_w3_cohort <- df_netsurv |> 
  filter(wave == "Wave3") |>
  filter(altrelucat == "Student") |>
  filter(egoid %in% egos_list, alterid %in% egos_list) |>
  # Exclude self-nominations if any exist
  filter(egoid != alterid)

cat("Number of within-cohort directed ties in Wave 3:", nrow(df_w3_cohort), "\n")

# 2. Extract vertex attributes for the nodes in our network --------------
# We construct a node attribute dataset for all unique individuals 
# involved in these within-cohort ties.
active_nodes <- unique(c(df_w3_cohort$egoid, df_w3_cohort$alterid))
cat("Number of active nodes in the within-cohort network:", length(active_nodes), "\n")

df_nodes <- df_basicsurv |>
  filter(egoid %in% active_nodes) |>
  select(egoid, gender_1, race_1, yourelig_1) |>
  mutate(
    religion = as.character(yourelig_1),
    gender = as.character(gender_1),
    race = as.character(race_1)
  ) |>
  # Clean names and handle NAs
  mutate(
    religion = ifelse(is.na(religion), "Unknown", religion),
    gender = ifelse(is.na(gender), "Unknown", gender),
    race = ifelse(is.na(race), "Unknown", race)
  )

# 3. Create Network Object ------------------------------------------------
# Create an empty directed network with the specified number of nodes
num_nodes <- length(active_nodes)
net <- network.initialize(n = num_nodes, directed = TRUE, multiple = FALSE)

# Map node IDs to 1-indexed network vertex indices
node_map <- setNames(seq_len(num_nodes), active_nodes)

# Add edges to the network
edges_matrix <- matrix(NA, nrow = nrow(df_w3_cohort), ncol = 2)
for (i in seq_len(nrow(df_w3_cohort))) {
  edges_matrix[i, 1] <- node_map[as.character(df_w3_cohort$egoid[i])]
  edges_matrix[i, 2] <- node_map[as.character(df_w3_cohort$alterid[i])]
}
# Filter out any unresolved mappings if any node was omitted
edges_matrix <- edges_matrix[!is.na(edges_matrix[,1]) & !is.na(edges_matrix[,2]), ]
add.edges(net, tail = edges_matrix[,1], head = edges_matrix[,2])

# Set network vertex attributes
# Match the order of nodes in the network
net_nodes_ids <- names(node_map)
df_nodes_ordered <- data.frame(egoid = as.numeric(net_nodes_ids)) |>
  left_join(df_nodes, by = "egoid")

set.vertex.attribute(net, "religion", df_nodes_ordered$religion)
set.vertex.attribute(net, "gender", df_nodes_ordered$gender)
set.vertex.attribute(net, "race", df_nodes_ordered$race)

# 4. Fit Exponential Random Graph Models (ERGMs) --------------------------
cat("Fitting ERGM models...\n")

# Model A: Baseline density, reciprocity, and religious homophily
# 'nodematch' with diff=TRUE fits separate homophily terms for each religion.
model_ergm_a <- ergm(net ~ edges + 
                       mutual + 
                       nodematch("gender") + 
                       nodematch("race") + 
                       nodematch("religion", diff = TRUE))

cat("\n======================================================\n")
cat("ERGM MODEL A Summary:\n")
cat("======================================================\n")
print(summary(model_ergm_a))

# Model B: Adding structural controls for popular people (gwidegree/gwodegree) 
# and structural triadic closure/transitivity (gwnsp). 
# This is the gold-standard specification for directed networks.
model_ergm_b <- ergm(net ~ edges + 
                       mutual + 
                       gwidegree(decay = 0.5, fixed = TRUE) + 
                       gwodegree(decay = 0.5, fixed = TRUE) + 
                       gwnsp(alpha = 0.5, fixed = TRUE) + 
                       nodematch("gender") + 
                       nodematch("race") + 
                       nodematch("religion", diff = TRUE))

cat("\n======================================================\n")
cat("ERGM MODEL B (Structural & Attribute) Summary:\n")
cat("======================================================\n")
print(summary(model_ergm_b))
