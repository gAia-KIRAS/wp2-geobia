library(sf)
library(dplyr)
library(qs)

ncores <- 16L

# AOI
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

# AOI dataframe
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

litho_reclass <- readr::read_tsv("doc/data_description/reclass_geology.tsv") |>
  mutate(
    lithology = as.integer(class),
    leg_litho = as.integer(leg_litho)
  ) |>
  select(leg_litho, lithology)

# wget https://gis.geologie.ac.at/inspire/download/insp_ge_gu_500k_epsg4258.gpkg
st_layers("dat/raw/geology/200k/Geologie_Kaernten_200.000.gpkg")
lithology <- read_sf("dat/raw/geology/200k/Geologie_Kaernten_200.000.gpkg", layer = "Geologie 200.000") |>
  st_transform(3416) |>
  select(leg_litho, geom) |>
  left_join(litho_reclass, by = "leg_litho") |>
  select(lithology, geom)

res_lithology <- st_join(grd, lithology) |>
  select(-idx) |>
  mutate(lithology = as.factor(lithology))

qsave(res_lithology, "dat/interim/misc_aoi/lithology_full.qs", nthreads = ncores)
