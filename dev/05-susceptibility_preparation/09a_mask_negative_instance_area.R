print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(qs)
  library(glue)
  library(tictoc)
})

source("dev/utils.R")

ncores <- 32L

wall("{Sys.time()} -- reading inventory")
inv <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
  mutate(slide = TRUE) |>
  select(slide, geom) |>
  st_transform(3416) |>
  st_buffer(units::as_units(1000, "m")) |>
  st_union()

wall("{Sys.time()} -- reading AOI")
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

wall("{Sys.time()} -- cutting holes")
absence_area <- st_difference(aoi, inv)
if (!file.exists("dat/interim/aoi/absence_area.gpkg")) {
  st_write(absence_area, "dat/interim/aoi/absence_area.gpkg")
}

wall("{Sys.time()} -- reading target grid")
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

wall("{Sys.time()} -- performing spatial join") # 420 sec
tic()
absence_grid <- st_join(grd, absence_area, join = st_intersects, left = TRUE) |>
  select(-idx) |>
  sfc_as_cols() |>
  st_drop_geometry() |>
  mutate(neg_sample = if_else(is.na(area), FALSE, TRUE)) |>
  select(neg_sample, x, y)
toc()

stopifnot(nrow(absence_grid) == nrow(grd))

wall("{Sys.time()} -- saving result")
qsave(absence_grid, "dat/interim/aoi/gaia_ktn_absence_grid.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")
