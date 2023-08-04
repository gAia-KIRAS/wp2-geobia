library(sf)
library(dplyr)
library(tibble)

# lookup-table for selected processes
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

# AOI
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
    st_transform(3416)

# GEORIOS export (2023-08-01)
read_sf("dat/interim/inventory/GEORIOS_for_gAia.gpkg") |>
    filter(CODE %in% process_types$ID) |>
    left_join(process_types, join_by(CODE == ID)) |>
    st_transform(3416) |>
    st_filter(aoi) |>
    write_sf("dat/processed/inventory_date_info.gpkg")
