library(dplyr)
library(sf)
library(qs)
library(arrow)
library(sfarrow)

source("dev/utils.R")

# expected number of pixels: 57,842,689

# terrain features
dtm <- qread("dat/interim/dtm_aoi/dtm_full.qs", nthreads = 64L)

# land cover, forest cover
lc <- qread("dat/interim/misc_aoi/land_cover_full.qs", nthreads = 64L)
identical(st_coordinates(dtm), st_coordinates(lc))

# climate indicators
ci <- qread("dat/interim/misc_aoi/climate_indices.qs", nthreads = 64L)
identical(st_coordinates(dtm), st_coordinates(ci))

# surface water
sw <- qread("dat/interim/misc_aoi/surface_water.qs", nthreads = 64L)

# merge all data sets
out <- dtm |>
  bind_cols(lc |> st_drop_geometry()) |>
  bind_cols(ci |> st_drop_geometry()) |>
  bind_cols(sw |> st_drop_geometry()) |>
  rename_with(.fn = \(x) gsub("-", "_", x), .cols = everything())

# save w/ simple feature geometry column (parquet)
st_write_parquet(obj = out, dsn = "dat/processed/carinthia_10m.parquet")

# save w/o simple feature geometry (ipc / arrow)
res <- out |>
  sfc_as_cols() |>
  st_drop_geometry()
write_ipc_file(res, sink = "dat/processed/carinthia_10m.arrow", compression = "lz4")
