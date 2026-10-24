# Header ------------------------------------------------------------------
# Title: load_alter_alter_edgelist
# Author: Posit Assistant (Omar Lizardo)
# Created: 2026-10-23
# Purpose: Load and validate the NetHealth Alter-Alter Edge List
#          (Data/AlterAlterEdgeList.csv). An ego-alter record is one of the ego's
#          nominations. An alter-alter record says that, in a given wave, the ego
#          reported that two of her named alters know each other (an unordered
#          pair). Provenance and the values checked here are in Data/README.md.
# Usage:   source(here::here("Code", "load_alter_alter_edgelist.R"))
#          ae <- load_alter_alter_edgelist(type = "alter_alter")

# Load libraries -----------------------------------------------------------
library(readr)
library(dplyr)

# Loader -------------------------------------------------------------------
load_alter_alter_edgelist <- function(type = c("all", "alter_alter", "ego_alter"),
                                      path = here::here("Data", "AlterAlterEdgeList.csv")) {
  type <- match.arg(type)

  # Values recorded in Data/README.md (checked 2026-10-23)
  expected <- list(
    md5 = "a55a32c387ab057f30aff9531b4ed366",
    n_records = 174748L,
    n_ego_alter = 35890L,
    n_alter_alter = 138858L,
    n_egos = 709L,
    n_distinct_vertex1 = 12968L,
    n_distinct_vertex2 = 15753L,
    wave_counts = c(37874L, 37864L, 22829L, 19824L, 18702L, 14827L, 13063L, 9765L)
  )

  if (!file.exists(path)) stop("Edge list not found: ", path, call. = FALSE)
  md5 <- unname(tools::md5sum(path))
  if (!identical(md5, expected$md5)) {
    stop("Checksum mismatch for ", basename(path), " (got ", md5, ", expected ",
         expected$md5, "). See Data/README.md before changing this file.", call. = FALSE)
  }

  d <- read_csv(path, col_types = cols(
    egoid = col_double(),
    vertex1 = col_double(),
    vertex2 = col_double(),
    wave = col_integer()
  ), show_col_types = FALSE)

  fail <- function(check) stop("Edge list check failed: ", check, call. = FALSE)
  if (!identical(names(d), c("egoid", "vertex1", "vertex2", "wave"))) fail("columns")
  if (nrow(d) != expected$n_records) fail("record count")
  if (anyNA(d)) fail("missing values")
  if (!identical(as.integer(table(factor(d$wave, levels = 1:8))), expected$wave_counts)) {
    fail("records by wave")
  }
  if (n_distinct(d$egoid) != expected$n_egos) fail("number of egos")
  if (n_distinct(d$vertex1) != expected$n_distinct_vertex1) fail("distinct vertex1")
  if (n_distinct(d$vertex2) != expected$n_distinct_vertex2) fail("distinct vertex2")
  if (any(duplicated(d))) fail("exact duplicate records")
  if (any(d$vertex1 == d$vertex2)) fail("self-loops")
  if (any(d$vertex2 == d$egoid)) fail("reporter named as vertex2")

  d <- d |>
    mutate(
      wave_label = paste0("Wave", wave),
      tie_type = if_else(vertex1 == egoid, "ego_alter", "alter_alter")
    )

  if (sum(d$tie_type == "ego_alter") != expected$n_ego_alter) fail("ego-alter record count")
  aa <- filter(d, tie_type == "alter_alter")
  if (nrow(aa) != expected$n_alter_alter) fail("alter-alter record count")
  pair_key <- paste(aa$egoid, pmin(aa$vertex1, aa$vertex2), pmax(aa$vertex1, aa$vertex2), aa$wave)
  if (anyDuplicated(pair_key)) fail("alter pair recorded twice in one ego-wave")

  if (type == "all") d else filter(d, tie_type == type)
}
