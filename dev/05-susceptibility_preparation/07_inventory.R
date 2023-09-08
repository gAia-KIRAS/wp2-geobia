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

wall("{Sys.time()} -- reading inventories")

# after filting by process type, 1415/1962 events remain
inv_georios <- read_sf("dat/interim/inventory/GEORIOS_for_gAia.gpkg") |>
  filter(CODE %in% process_types$ID) |>
  st_geometry() |>
  st_transform(3416) |>
  st_as_sf() |>
  rename(geom = x) |>
  mutate(slide = 1L)

# 2704 events
inv_valid <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
  st_geometry() |>
  st_transform(3416) |>
  st_as_sf() |>
  rename(geom = x) |>
  mutate(slide = 2L)

# combine inventory locations: 4119 events
inv <- bind_rows(inv_valid, inv_georios) |>
  st_buffer(dist = units::as_units(5, "m"))
wall("    number of landslide events (validated: 2, not validated: 1)")
table(inv$slide)

wall("{Sys.time()} -- reading target grid")
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

wall("{Sys.time()} -- performing spatial join")
# left spatial join results in 184 duplicates
# 0: 57840030 --> 57840030
# 1:      706 -->      675
# 2:     2137 -->     1984
tic()
inventory <- st_join(grd, inv, join = st_intersects, left = TRUE) |>
  select(-idx) |>
  sfc_as_cols() |>
  st_drop_geometry() |>
  mutate(across(x:y, as.integer)) |>
  mutate(slide = tidyr::replace_na(slide, 0)) |>
  group_by(x, y) |>
  summarise(slide = max(slide)) |>
  ungroup()
toc()

stopifnot(nrow(inventory) == nrow(grd))

wall("{Sys.time()} -- saving result")
qsave(inventory, "dat/interim/misc_aoi/inventory.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")
