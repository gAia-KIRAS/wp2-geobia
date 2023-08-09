print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(qs)
  library(arrow)
  library(sfarrow)
  library(glue)
})

source("dev/utils.R")

ncores <- 64L

# expected number of pixels: 57,842,689

# terrain features
print(glue("{Sys.time()} -- reading terrain features"))
dtm <- qread("dat/interim/dtm_aoi/dtm_full.qs", nthreads = ncores) |>
  mutate(geomorphons = as.factor(geomorphons))

# land cover, forest cover
print(glue("{Sys.time()} -- reading land cover features"))
lc <- qread("dat/interim/misc_aoi/land_cover_full.qs", nthreads = ncores)
stopifnot(identical(st_coordinates(dtm), st_coordinates(lc)))
lc <- lc |>
  st_drop_geometry() |>
  mutate(forest_cover = if_else(is.na(forest_cover), 0, forest_cover))

# climate indicators
print(glue("{Sys.time()} -- reading climate indicators"))
ci <- qread("dat/interim/misc_aoi/climate_indices.qs", nthreads = ncores)
stopifnot(identical(st_coordinates(dtm), st_coordinates(ci)))
ci <- st_drop_geometry(ci)

# surface water
print(glue("{Sys.time()} -- reading surface water features"))
sw <- qread("dat/interim/misc_aoi/surface_water.qs", nthreads = ncores)
stopifnot(identical(st_coordinates(dtm), st_coordinates(sw)))
sw <- sw |>
  st_drop_geometry() |>
  rename(
    sw_hazard_cat = Gefahrenkategorien,
    sw_max_speed = MaxGeschwindigkeit,
    sw_max_depth = MaxWassertiefe,
    sw_spec_runoff = SpezifischerAbfluss
  )

# distance to roads
print(glue("{Sys.time()} -- reading distance to roads"))
rd <- qread("dat/interim/misc_aoi/road_dist.qs", nthreads = ncores) |>
  select(dist)
stopifnot(nrow(rd) == nrow(dtm))

# geology
print(glue("{Sys.time()} -- reading geology"))
# TODO

# merge all data sets
print(glue("{Sys.time()} -- combining data sets"))
out <- dtm |>
  bind_cols(lc) |>
  bind_cols(ci) |>
  bind_cols(sw) |>
  bind_cols(rd) |>
  rename_with(.fn = \(x) gsub("-", "_", x), .cols = everything()) |>
  rename_with(.fn = tolower, .cols = everything())

# save w/ simple feature geometry column (parquet)
print(glue("{Sys.time()} -- writing parquet"))
st_write_parquet(obj = out, dsn = "dat/processed/carinthia_10m.parquet")
print(glue("    object size w/ sf geom:"))
format(object.size(out), "auto")

# save w/o simple feature geometry (ipc / arrow)
print(glue("{Sys.time()} -- writing ipc"))
res <- out |>
  sfc_as_cols() |>
  st_drop_geometry()
write_ipc_file(res, sink = "dat/processed/carinthia_10m.arrow", compression = "lz4")
print(glue("    object size w/o sf geom:"))
format(object.size(res), "auto")

print(glue("{Sys.time()} -- DONE \\o/"))
