library(dplyr)
library(tidyr)
library(sf)
library(stars)
library(qs)

ncores <- 32L

# AOI
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

# AOI dataframe
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

# Forest cover
wk <- read_stars("dat/interim/misc_aoi/wk_aoi_ktn.tif")
res_wk <- st_extract(x = wk, at = grd, bilinear = FALSE) |>
  rename(forest_cover = wk_aoi_ktn.tif) |>
  mutate(forest_cover = if_else(is.na(forest_cover), 0, forest_cover))
stopifnot(nrow(grd) == nrow(res_wk))
qsave(res_wk, "dat/interim/misc_aoi/forest_cover.qs", nthreads = ncores)

# Tree height
ndsm <- read_stars("dat/interim/dtm_derivates/ktn/als_nDSM_10m.tif")
res_ndsm <- st_extract(x = ndsm, at = grd, bilinear = FALSE) |>
  rename(tree_height = als_nDSM_10m.tif) |>
  mutate(tree_height = if_else(tree_height < 0, 0, tree_height)) |>
  mutate(tree_height = if_else(tree_height > 70, 70, tree_height)) |>
  mutate(tree_height = replace_na(tree_height, 0))
stopifnot(nrow(grd) == nrow(res_ndsm))
qsave(res_ndsm, "dat/interim/misc_aoi/tree_height.qs", nthreads = ncores)

# Corine Land Cover
clc <- read_sf("dat/raw/clc/CLC18_AT_clip.shp") |>
  st_transform(3416) |>
  mutate(CODE_18 = as.integer(CODE_18)) |>
  select(CLC = CODE_18, geometry)
res_clc <- st_join(grd, clc) |>
  select(-idx)
stopifnot(nrow(grd) == nrow(res_clc))
qsave(res_clc, "dat/interim/misc_aoi/clc.qs", nthreads = ncores)

# Land cover
lc <- read_stars("dat/interim/misc_aoi/cadasterenv_ktn.tif")
res_lc <- st_extract(x = lc, at = grd, bilinear = FALSE) |>
  rename(land_cover = cadasterenv_ktn.tif)
stopifnot(nrow(grd) == nrow(res_lc))
qsave(res_lc, "dat/interim/misc_aoi/land_cover.qs", nthreads = ncores)

stopifnot(identical(res_lc$geometry, res_wk$geometry))

res <- res_lc |>
  mutate(forest_cover = as.integer(res_wk$forest_cover)) |>
  mutate(tree_height = res_ndsm$tree_height) |>
  mutate(land_cover = as.factor(land_cover)) |>
  select(land_cover, forest_cover, tree_height, geometry)
qsave(res, "dat/interim/misc_aoi/land_forest_cover.qs", nthreads = ncores)
