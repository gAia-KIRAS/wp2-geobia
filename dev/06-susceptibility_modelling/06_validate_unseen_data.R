# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# tune and train random forest
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("sf")
  library("dplyr")
  library("glue")
  library("qs")
})

print(glue::glue("{Sys.time()} -- loading data"))
res <- qread("dat/processed/prediction_mean_sd_sf.qs", nthreads = 32L)

# TODO - extract susceptibility values for:
# - GEORIOS
# - KAGIS 2018-2021
# - Polygone
