library(sf)
library(dplyr)
library(tibble)
library(qs)

ncores <- 64L

process_types <- tribble(
  ~ID, ~PROCESS,
  "130.500", "Bereich mit Rutsch- / Gleitprozessen",
  "130.000", "Gleiteh/Rutschen",
  "144.000", "Hangmure",
  "132.000", "Lockergesteinsrutschung",
  "152.000", "LG-Rutschung bis Hangmure",
  "192.000", "Massenbewegung im LG",
  "194.000", "Rutschung oder Hangmure",
  "195.000", "Uferanbruch bzw. Rutschung"
)

# after filting by process type, 1415/1962 events remain
inv_georios <- read_sf("dat/interim/inventory/GEORIOS_for_gAia.gpkg") |>
  filter(CODE %in% process_types$ID) |>
  st_geometry() |>
  st_transform(3416)

# 2704 events
inv_valid <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
  st_geometry() |>
  st_transform(3416)

# simply combine inventory locations
inv <- c(inv_valid, inv_georios)

rm(inv_georios, inv_valid, process_types)

grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

inventory <- st_join(grd, inv)
qsave(inventory, "dat/interim/misc_aoi/inventory.qs", nthreads = ncores)
