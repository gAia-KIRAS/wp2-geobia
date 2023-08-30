library(sf)
library(dplyr)
library(qs)

ncores <- 12L

# AOI
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

# AOI dataframe
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

st_layers("dat/raw/geology/insp_ge_gu_500k_epsg4258.gpkg")
lithology <- read_sf("dat/raw/geology/insp_ge_gu_500k_epsg4258.gpkg", layer = "geologicunitview") |>
  select(lithology = representativeLithology) |>
  mutate(lithology = as.factor(lithology)) |>
  st_transform(3416)

res_lithology <- st_join(grd, lithology) |>
  select(-idx)

qsave(res_lithology, "dat/interim/misc_aoi/lithology_full.qs", nthreads = ncores)
