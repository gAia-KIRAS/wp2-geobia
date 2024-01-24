library(dplyr)
library(tidyr)
library(sf)

source("dev/utils.R")

ls_scars_merge <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
  mutate(event_date = NA) |>
  mutate(TYP_CODE = if_else(is.na(TYP_CODE), Subkat_MO, TYP_CODE)) |>
  select(
    WIS_ID, OBJECTID,
    process_type = TYP_CODE, event_date,
    source = Grundlage, last_update = AKT_DATE, modified = gaia_check
  ) |>
  mutate(
    OBJECTID = as.character(WIS_ID),
    last_update = if_else(last_update == as.Date("1899-12-30"), NA, last_update)
  )

inventar_kaernten <- read_sf("dat/processed/Ereignisinventar_konsolidiert/Ereignisinventar_konsolidiert_clipped_v3.gpkg") |>
  rename_all(tolower) |>
  rename(object_id = objectid)

length(identify_dups(inventar_kaernten, wis_id)) # 63
length(identify_dups(inventar_kaernten, object_id)) #  3
length(identify_dups(inventar_kaernten, gr_nr)) #  0
length(identify_dups(inventar_kaernten, urspr_nr)) #  2

d_w <- list_dups(inventar_kaernten, wis_id)
d_o <- list_dups(inventar_kaernten, object_id)
d_u <- list_dups(inventar_kaernten, urspr_nr)

# filter entries with duplicated wis_id from ls_scars_merge: 81 rows
lssm_wis <- ls_scars_merge |>
  filter(WIS_ID %in% d_w$wis_id) |>
  arrange(WIS_ID)

# 20 entries of these are duplicates in ls_scars_merge
list_dups(lssm_wis, WIS_ID)

# manually corrected wis duplicates
lssm_wis_corr <- read_sf("dat/interim/wis_id_dupl.shp") |>
  mutate(
    last_update = as.Date("2021-12-06"),
    event_date = NA, 
    source = "KAGIS",
    gr_nr = NA, urspr_nr = NA, checked = TRUE, loc_qual = 0) |>
  select(
    wis_id = WIS_ID, object_id = OBJECTID, gr_nr, urspr_nr, process_type = process_ty,
  event_date, source, last_update, modified, checked, loc_qual, geom = geometry
  ) |>
  st_transform(3416)

# remove 124 entries with duplicated wis_id
res <- inventar_kaernten |>
  filter(!(wis_id %in% d_w$wis_id)) |>
  bind_rows(lssm_wis_corr) |>
  filter(process_type != "Bergsturz") |>
  mutate(
    event_date = as.Date(event_date),
    process_type = gsub("Bereich mit Rutsch- / Gleitprozessen", "Gleiten/Rutschen", process_type),
    process_type = gsub("Gleiteh/Rutschen", "Gleiten/Rutschen", process_type),
    process_type = gsub("Massenbewegung im LG", "Lockergesteinsrutschung", process_type),
    process_type = gsub("LG-Rutschung bis Hangmure", "Rutschung oder Hangmure", process_type),
    process_type = gsub("KEIN DETAIL", "Gleiten/Rutschen", process_type),
    process_type = gsub("keine Angabe", "Gleiten/Rutschen", process_type)
  )
