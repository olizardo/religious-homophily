
# Header ------------------------------------------------------------------

# Name: create_egonet_list
# Purpose: Create a list of igraph objects for egonet analysis 
# Author: Michael Lee Wood


# Load Packages -----------------------------------------------------------

library(igraph)
library(dplyr)
library(here)




# Load and Prep Data ------------------------------------------------------

#load ego-network edge list 
df_egonet_edges <- read.csv(here('data', 'AlterAlterEdgeList(1-26-20).csv'))

# subset the data to W3
df_egonet_edges <- df_egonet_edges |> 
  filter(wave == 3)

# remove W3 var
df_egonet_edges <- df_egonet_edges |> 
  select(-wave)

df_egonet_edges <- df_egonet_edges |> 
  filter(egoid %in% char_v_egoids)


# get char vector of egoids
char_egoids <- as.character(unique(df_egonet_edges$egoid))

list_egonet_edges <- df_egonet_edges |> 
  group_by(egoid) |> 
  group_split()


names(list_egonet_edges) <- char_egoids

list_egonet_edges <- lapply(list_egonet_edges, function(x){x <- x |> select(-egoid)})


list_graphs <- lapply(list_egonet_edges, 
                      function(x){graph_from_edgelist(x, directed = FALSE)})
igraph_o <- graph_from_edgelist(list_egonet_edges[[1]], directed = FALSE)

mat_test <- as.matrix(list_egonet_edges[[1]])
igraph_o <- graph_from_edgelist(mat_test, directed = FALSE)
igraph_o.degree()
plot(igraph_o)

# DF for EACH EGO 
# vertex name
# vertex relig

df_vertices <- df_w3_comb_data |> 
  select(egoid, alterid, yourelig_1, altrelig)


df_test <- list_df_vertices[[1]]

create_vertex_df <- function(df){
  df_test_ego <- df_test |> 
    select(egoid,yourelig_1) |> 
    unique()
  df_test_ego <- df_test_ego |> 
    rename("id"="egoid","relig"="yourelig_1")
  
  df_test_alter <- df_test |> 
    select(alterid,altrelig)
  df_test_alter <- df_test_alter |> 
    rename("id"="alterid","relig"="altrelig")
  df_test_new <- bind_rows(df_test_ego, df_test_alter)
}

df_test_edges <- list_egonet_edges[[1]]

g_test <- graph_from_data_frame(df_test_edges, directed = FALSE, vertices = df_test_new)
plot(g_test)

V(g_test)
g_test_e <- make_ego_graph(g_test,nodes="10153")
plot(g_test_e[[1]])
V(g_test_e[[1]])$relig

g <- graph_from_data_frame(relations, directed=TRUE, vertices=actors)
g
char_v_egoids <- as.character(unique(df_vertices$egoid))


list_df_vertices <- df_vertices |> 
  group_by(egoid) |> 
  group_split()

#DF for EACH EGO
# edge list





## The typical case is that these tables are read in from files....
actors <- data.frame(name=c("Alice", "Bob", "Cecil", "David",
                            "Esmeralda"),
                     age=c(48,33,45,34,21),
                     gender=c("F","M","F","M","F"))
relations <- data.frame(from=c("Bob", "Cecil", "Cecil", "David",
                               "David", "Esmeralda"),
                        to=c("Alice", "Bob", "Alice", "Alice", "Bob", "Alice"),
                        same.dept=c(FALSE,FALSE,TRUE,FALSE,FALSE,TRUE),
                        friendship=c(4,5,5,2,1,1), advice=c(4,5,5,4,2,3))
g <- graph_from_data_frame(relations, directed=TRUE, vertices=actors)
print(g, e=TRUE, v=TRUE)

## The opposite operation
as_data_frame(g, what="vertices")
as_data_frame(g, what="edges")

g <- graph_from_data_frame(list_egonet_edges[[1]],list_df_vertices[[1]])

