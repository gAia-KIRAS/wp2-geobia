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

ncores <- 16L

# expected number of pixels: 57,842,689
# grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)
# nrow(grd)

# terrain features
print(glue("{Sys.time()} -- reading terrain features"))
dtm <- qread("dat/interim/dtm_aoi/dtm_full.qs", nthreads = ncores) |>
  mutate(geomorphons = as.factor(geomorphons))

# land cover, forest cover, tree height
print(glue("{Sys.time()} -- reading land cover features"))
lc <- qread("dat/interim/misc_aoi/land_forest_cover.qs", nthreads = ncores)
stopifnot(identical(st_coordinates(dtm), st_coordinates(lc)))
lc <- st_drop_geometry(lc)

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
  select(road_dist = dist)
stopifnot(nrow(rd) == nrow(dtm))

# lithology
print(glue("{Sys.time()} -- reading lithology"))
li <- qread("dat/interim/misc_aoi/lithology_full.qs", nthreads = ncores) |>
  st_drop_geometry() |>
  select(lithology)
stopifnot(nrow(li) == nrow(dtm))

# effectively surveyed area
print(glue("{Sys.time()} -- reading esa"))
esa <- qread("dat/interim/misc_aoi/esa.qs", nthreads = ncores) |>
  st_drop_geometry() |>
  select(esa)
stopifnot(nrow(esa) == nrow(dtm))

# inventory
print(glue("{Sys.time()} -- reading inventory"))
inv <- qread("dat/interim/misc_aoi/inventory.qs", nthreads = ncores) |>
  select(slide)
stopifnot(nrow(inv) == nrow(dtm))

# merge all data sets
print(glue("{Sys.time()} -- combining data sets"))
out <- dtm |>
  bind_cols(lc) |>
  bind_cols(ci) |>
  bind_cols(sw) |>
  bind_cols(rd) |>
  bind_cols(li) |>
  bind_cols(esa) |>
  bind_cols(inv) |>
  rename_with(.fn = \(x) gsub("-", "_", x), .cols = everything()) |>
  rename_with(.fn = tolower, .cols = everything()) |>
  select(slide, everything())

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
