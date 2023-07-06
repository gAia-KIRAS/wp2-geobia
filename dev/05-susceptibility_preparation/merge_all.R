library(dplyr)
library(sf)
library(qs)
library(arrow)
library(sfarrow)

source("dev/utils.R")

dtm <- qread("dat/interim/dtm_aoi/dtm_full.qs", nthreads = 64L)
lc <- qread("dat/interim/misc_aoi/land_cover_full.qs", nthreads = 64L)
identical(st_coordinates(dtm), st_coordinates(lc))

ci <- qread("dat/interim/misc_aoi/climate_indices.qs", nthreads = 64L)
identical(st_coordinates(dtm), st_coordinates(ci))

out <- dtm |>
  bind_cols(lc |> st_drop_geometry()) |>
  bind_cols(ci |> st_drop_geometry()) |>
  rename_with(.fn = \(x) gsub("-", "_", x), .cols = everything())

st_write_parquet(obj = out, dsn = "dat/processed/carinthia_10m.parquet")

res <- out |>
  sfc_as_cols() |>
  st_drop_geometry()

write_ipc_file(res, sink = "dat/processed/carinthia_10m.arrow", compression = "lz4")
