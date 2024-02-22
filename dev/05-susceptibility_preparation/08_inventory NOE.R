suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(tibble)
  library(glue)
  library(qs)
  library(tictoc)
})

source("wp2-geobia/dev/utils.R")

ncores <- 64L

# process_types <- tribble(
#   ~ID, ~PROCESS,
#   "130.500", "Bereich mit Rutsch- / Gleitprozessen",
#   "130.000", "Gleiteh/Rutschen",
#   "144.000", "Hangmure",
#   "132.000", "Lockergesteinsrutschung",
#   "152.000", "LG-Rutschung bis Hangmure",
#   "192.000", "Massenbewegung im LG",
#   "194.000", "Rutschung oder Hangmure",
#   "195.000", "Uferanbruch bzw. Rutschung"
# )

wall("{Sys.time()} -- reading inventories")

# AOI
# aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
#   st_transform(3416)

# after filting by process type, 1415/1962 events remain
# inv_georios <- read_sf("dat/interim/inventory/GEORIOS_for_gAia.gpkg") |>
#   filter(CODE %in% process_types$ID) |>
#   st_geometry() |>
#   st_transform(3416) |>
#   st_as_sf() |>
#   rename(geom = x) |>
#   mutate(slide = 2L) |>
#   st_intersection(aoi)

# 2704 events
#inv_valid <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
#  st_geometry() |>
#  st_transform(3416) |>
#  st_as_sf() |>
#  rename(geom = x) |>
#  mutate(slide = 1L)

# combine inventory locations: 4119 events
# inv <- bind_rows(inv_valid, inv_greorios) |>
# st_buffer(dist = units::as_units(5, "m")) |>
#  group_by(slide) |>
#  summarize(geom = st_union(geom))

# buffer only validated inventory
#inv <- inv_valid %>%
#  st_buffer(dist = units::as_units(5, "m")) %>%
#  group_by(slide) %>%
#  summarize(geom = st_union(geom))

#wall("{Sys.time()} -- reading target grid")
#grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

#wall("{Sys.time()} -- performing spatial join") # 500 sec elapsed
#tic()
#inventory <- st_join(grd, inv, join = st_intersects, left = TRUE) |>
#  select(-idx) |>
#  sfc_as_cols() |>
#  st_drop_geometry() |>
#  mutate(across(x:y, as.integer)) |>
#  mutate(slide = tidyr::replace_na(slide, 0)) |>
#  mutate(slide = as.logical(slide))
#toc()

# 0: 57840705
# 1:     1984

#stopifnot(nrow(inventory) == nrow(grd))

#wall("{Sys.time()} -- saving result")
#qsave(inventory, "dat/interim/misc_aoi/inventory.qs", nthreads = ncores)
#wall("{Sys.time()} -- DONE")

# NOE data
inv_pts <- read_sf("wp2-geobia/dat/interim/noe-inventory/noe/ALS_Massenbewegungskartierung_MONOE.shp") %>%
  st_geometry() %>%
  st_transform(3416) %>%
  st_as_sf() %>%
  rename(geom = x) %>%
  mutate(slide = 1L)

# buffer consolidated inventory
inv <- inv_pts %>%
  st_buffer(dist = units::as_units(5, "m")) %>%
  group_by(slide) %>%
  summarize(geom = st_union(geom))

wall("{Sys.time()} -- reading target grid")
grd <- qread("wp2-geobia/dat/interim/aoi/gaia_neo_grid.qs", nthreads = ncores)

wall("{Sys.time()} -- performing spatial join") # 500 sec elapsed
tic()
inventory <- st_join(grd, inv, join = st_intersects, left = TRUE) %>%
  select(-idx) %>%
  sfc_as_cols() %>%
  st_drop_geometry() %>%
  mutate(across(x:y, as.integer)) %>%
  mutate(slide = tidyr::replace_na(slide, 0)) %>%
  mutate(slide = as.logical(slide))
toc()

stopifnot(nrow(inventory) == nrow(grd))

wall("{Sys.time()} -- saving result")
qsave(inventory, "wp2-geobia/dat/interim/misc_aoi/inventory.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")

