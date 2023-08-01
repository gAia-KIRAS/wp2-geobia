library(sf)
library(dplyr)

# consolidated inventory
gaia_inv <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg")

# GEORIOS export (2023-08-01)
georios <- read_sf("dat/interim/inventory/GEORIOS_for_gAia.gpkg")

# TODO: how to join?
