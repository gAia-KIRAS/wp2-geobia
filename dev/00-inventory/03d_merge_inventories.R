# merge inventory v1, Restpunkte_Polygon_Hannah, Rutschungsflaechen_Punkt and Rutschungen_FeldApp.shp

library(tidyverse)
library(sf)

# load input files
v1 <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v1.shp")
rp_pol_hannah <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Restpunkte_Polygon_Hannah.shp")
kagis_points <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Rutschungsflaechen_Punkt.gpkg")
rp_pol_kagis <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Rutschungen_FeldApp.shp") |>
  st_set_crs(31258)
kagis_poly_unmatched_pol <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Rutschungsflaechen_unmatched.gpkg")

# check if crs is equal
objs <- list(st_crs(v1), st_crs(rp_pol_hannah), st_crs(kagis_points), st_crs(rp_pol_kagis))
outer(objs, objs, Vectorize(all.equal))

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
kagis_pol <- rp_pol_kagis |>
  mutate(WIS_ID = NA, OBJECTID = as.character(NA), process_type = NA, event_date = NA, source = "KAGIS-Flaechen", last_update = NA, modified = "Punkt ergaenzt", checked = TRUE) |>
  rename(fid = Id, geom = geometry) |>
  select(all_of(cn))

hannah_pol <- rp_pol_hannah |>
  mutate(WIS_ID = NA, OBJECTID = as.character(NA), process_type = NA, event_date = NA, source = "ALS-DGM", last_update = NA, modified = "Punkt ergaenzt", checked = TRUE) |>
  rename(fid = Id, geom = geometry) |>
  select(all_of(cn))

res <- inv |>
  bind_rows(pts, kagis_pol, hannah_pol) |>
  mutate(fid = as.integer(fid), process_type = as.factor(process_type), source = as.factor(source)) |>
  mutate(source = fct_recode(source, KAGIS = "KAGIS Ereigniskataster"))
  arrange(WIS_ID, OBJECT_ID, process_type, event_date)

table(res$source)

sum(duplicated(st_geometry(res))) # 1699

st_write(res, dsn = "dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v2.shp")
