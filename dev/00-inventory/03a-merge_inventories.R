# technical merge of GEORIOS and dataset validated by RS w/o content verification

library(sf)
library(dplyr)

# GEORIOS export (2023-08-01)
georios <- read_sf("dat/processed/inventory_date_info.gpkg") |>
  mutate(source = "GEORIOS") |>
  select(gr_nr = GR_NR, process = PROCESS, source)

ls_scars_merge <- read_sf("dat/interim/inventory/LS_scars_merge.gpkg") |>
  st_transform(3416) |>
  mutate(id = row_number()) |>
  select(id, source = Grundlage) |>
  mutate(source = if_else(is.na(source), "KAGIS", source)) |>
  mutate(source = gsub(" Ereigniskataster", "", source))

inventory <- georios |>
  bind_rows(ls_scars_merge) |>
  select(source, gr_nr, id, process, geom)

st_write(inventory, "dat/interim/inventory/LS_scars_merge_georios.gpkg")
