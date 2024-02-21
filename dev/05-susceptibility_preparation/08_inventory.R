suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(tibble)
  library(glue)
  library(qs)
  library(tictoc)
})

source("dev/utils.R")

ncores <- 32L

wall("{Sys.time()} -- reading inventory")

# AOI
# aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
#   st_transform(3416)

# 1973 events
inv_pts <- read_sf("dat/reporting/inventory_carinthia.gpkg") |>
  st_geometry() |>
  st_transform(3416) |>
  st_as_sf() |>
  rename(geom = x) |>
  mutate(slide = 1L)

# buffer consolidated inventory
inv <- inv_pts |>
  st_buffer(dist = units::as_units(5, "m")) |>
  group_by(slide) |>
  summarize(geom = st_union(geom))

wall("{Sys.time()} -- reading target grid")
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

wall("{Sys.time()} -- performing spatial join") # 500 sec elapsed
tic()
inventory <- st_join(grd, inv, join = st_intersects, left = TRUE) |>
  select(-idx) |>
  sfc_as_cols() |>
  st_drop_geometry() |>
  mutate(across(x:y, as.integer)) |>
  mutate(slide = tidyr::replace_na(slide, 0)) |>
  mutate(slide = as.logical(slide))
toc()

# 0: 57841130
# 1:     1559

stopifnot(nrow(inventory) == nrow(grd))

wall("{Sys.time()} -- saving result")
qsave(inventory, "dat/interim/misc_aoi/inventory.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")
