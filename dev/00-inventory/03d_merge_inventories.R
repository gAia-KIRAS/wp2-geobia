# merge inventory v1, Restpunkte_Polygon_Hannah, Rutschungsflaechen_Punkt and Rutschungen_FeldApp.shp

library(tidyverse)
library(sf)

library(sf)
library(dplyr)
library(tibble)

# extract sfc to x and y cols
sfc_as_cols <- function(x, geometry, names = c("x", "y"), drop_sfg = FALSE) {
  if (missing(geometry)) {
    geometry <- sf::st_geometry(x)
  } else {
    geometry <- rlang::eval_tidy(enquo(geometry), x)
  }
  stopifnot(inherits(x, "sf") && inherits(geometry, "sfc_POINT"))
  ret <- sf::st_coordinates(geometry)
  ret <- tibble::as_tibble(ret)
  stopifnot(length(names) == ncol(ret))
  x <- x[, !names(x) %in% names]
  ret <- setNames(ret, names)
  ret <- dplyr::bind_cols(x, ret)
  if (drop_sfg) ret <- st_drop_geometry(ret)
  return(ret)
}

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
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg")

# GEORIOS export (2023-08-01)
georios <- read_sf("dat/interim/inventory/GEORIOS_for_gAia.gpkg") |>
  filter(CODE %in% process_types$ID) |>
  left_join(process_types, join_by(CODE == ID)) |>
  mutate(CODE = as.numeric(CODE), source = "GEORIOS", last_update = NA, modified = NA, checked = FALSE) |>
  st_transform(31258) |>
  st_filter(aoi) |>
  select(GR_NR, URSPR_NR, process_type = PROCESS, event_date = EREIGNIS_d, loc_qual = QUAL_LAGE, source, last_update, modified, checked, geom = SHAPE)

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
  mutate(loc_qual = 0) |>
  bind_rows(georios) |>
  mutate(fid = as.integer(fid), process_type = as.factor(process_type), source = as.factor(source), loc_qual = as.integer(loc_qual)) |>
  mutate(source = fct_recode(source, KAGIS = "KAGIS Ereigniskataster")) |>
  mutate(source = fct_relevel(source, "KAGIS", "GEORIOS", "ALS-DGM", "KAGIS-Flaechen")) |>
  select("fid", "WIS_ID", "OBJECTID", "GR_NR", "URSPR_NR", "process_type", "event_date", "source", "last_update", "modified", "checked", "loc_qual", "geom")

table(res$source)

# remove duplicates
sum(duplicated(st_geometry(res))) # 1727

final_inventory <- res |>
  arrange(process_type, event_date, source) |>
  sfc_as_cols() |>
  group_by(x, y) |>
  slice(1) |>
  select(-x, -y) |>
  st_transform(3416)

table(final_inventory$source)
sum(duplicated(st_geometry(final_inventory)))

final_inventory |>
  st_write(dsn = "dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v3.gpkg")

final_inventory |>
  select(-fid) |>
  st_write(dsn = "dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v3.gpkg")
