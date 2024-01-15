# merge inventory v1, Restpunkte_Polygon_matched and Rutschungsflaechen_Punkt

library(tidyverse)
library(sf)

v1 <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v1.shp")
rp_pol_matched <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Restpunkte_Polygon_matched.shp")
kagis_poly_unmatched_pol <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Rutschungsflaechen_unmatched.gpkg")
kagis_points <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Rutschungsflaechen_Punkt.gpkg")

all.equal(st_crs(v1), st_crs(rp_pol_matched), st_crs(kagis_points)) # 31258

# fix column names in main inventory file
inv <- v1 |>
  rename(
    fid = fid_1,
    process_type = process_ty,
    last_update = last_updat,
    geom = geometry
  ) |>
  st_cast("POINT")
cn <- colnames(inv)

# adapt colnames in kagis pointfile to main inventory
pts <- kagis_points |>
  mutate(fid = 0, checked = NA, OBJECTID = as.character(OBJECTID), modified = as.character(modified)) |>
  select(all_of(cn))
all(cn == colnames(pts))

# match unmatched points to polygons
pol <- rp_pol_matched |>
  mutate(WIS_ID = NA, OBJECTID = as.character(NA), process_type = NA, event_date = NA, source = NA, last_update = NA, modified = as.character(NA), checked = TRUE) |>
  rename(fid = Id, geom = geometry) |>
  select(all_of(cn))

res <- inv |>
  bind_rows(pts, pol)

st_write(res, dsn = "dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v2.shp")
