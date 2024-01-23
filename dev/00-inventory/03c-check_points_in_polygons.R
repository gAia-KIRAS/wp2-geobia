# spatial join of KAGIS point and polygon data

library(tidyverse)
library(sf)

cn <- st_read(dsn = "dat/interim/MB_konsolidiert_v1.gpkg") |> 
  colnames()

poly <- read_sf("dat/interim/inventory/area_points/poly/Rutschungsflaechen.shp")
st_crs(poly)
pts <- read_sf("dat/interim/inventory/area_points/point/Rutschungen_FeldApp.shp") |> 
  st_set_crs(31258)

res <- st_join(pts, poly) |>
  mutate(WIS_ID = NA, process_type = NA, modified = TRUE, source = "KAGIS-Flaechen") |> 
  select(WIS_ID, OBJECTID, process_type, event_date = DATUM_VON, source, last_update = UPDATE_DAT, modified, geometry) |> 
st_write(dsn = "dat/interim/inventory/area_points/Rutschungsflaechen_Punkt.gpkg")

# 75 slides remain without point
nrow(poly) - nrow(pts)

poly |>
  select(OBJECTID, YEAR, KATEGORIE, SHAPE_AREA) |> 
  filter(!OBJECTID %in% res$OBJECTID) |> 
  st_write("dat/interim/inventory/area_points/Rutschungsflaechen_unmatched.gpkg")
