library(sf)
library(dplyr)

kagis <- read_sf("dat/interim/MB_im_Detail_EI2023.shp") |>
  mutate(source = "KAGIS") |>
  select(
    WIS_ID, OBJECTID,
    process_type = TYP_CODE, event_date = EREIG_ZEIT,
    source, last_update = AKT_DATE, modified = Done
  ) |>
  mutate(modified = as.character(modified)) |>
  mutate(event_date = as.Date(event_date, format = "%d.%m.%Y")) |>
  rename(geom = geometry)

ls_scars_merge <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
  mutate(event_date = NA) |>
  mutate(if_else(is.na(TYP_CODE), Subkat_MO, TYP_CODE)) |>
  select(
    WIS_ID, OBJECTID,
    process_type = TYP_CODE, event_date,
    source = Grundlage, last_update = AKT_DATE, modified = gaia_check
  ) |>
  mutate(
    OBJECTID = as.character(WIS_ID),
    last_update = if_else(last_update == as.Date("1899-12-30"), NA, last_update)
  )

kagis |>
  bind_rows(ls_scars_merge) |>
  st_write(dsn = "dat/interim/MB_konsolidiert_v1.gpkg")
