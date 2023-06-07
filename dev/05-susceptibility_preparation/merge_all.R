library(dplyr)
library(sf)
library(qs)
library(arrow)
library(sfarrow)

source("dev/utils.R")

dtm <- qread("dat/interim/dtm_aoi/dtm_full.qs", nthreads = 64L)
lc <- qread("dat/interim/misc_aoi/land_cover_full.qs", nthreads = 64L)
identical(st_coordinates(dtm), st_coordinates(lc))

out <- dtm |>
  bind_cols(lc |> st_drop_geometry()) |>
  rename_with(.fn = \(x) gsub("-", "_", x), .cols = everything())

st_write_parquet(obj = out, dsn = "dat/processed/carinthia_10m.parquet")
