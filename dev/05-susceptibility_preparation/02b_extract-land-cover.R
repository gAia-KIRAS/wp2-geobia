library(dplyr)
library(sf)
library(stars)
library(qs)

# AOI
aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

# AOI dataframe
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 16L)

# Forest cover
wk <- read_stars("dat/interim/misc_aoi/wk_aoi_ktn.tif") |>
  st_as_sf(as_points = TRUE) |>
  rename(forest_cover = wk_aoi_ktn.tif)
res_wk <- st_join(grd, wk) |>
  select(-idx)
nrow(grd) == nrow(res_wk)
qsave(res_wk, "dat/interim/misc_aoi/forest_cover.qs", nthreads = 16L)

# Corine Land Cover
clc <- read_sf("dat/raw/clc/CLC18_AT_clip.shp") |>
  st_transform(3416) |>
  mutate(CODE_18 = as.integer(CODE_18)) |>
  select(CLC = CODE_18, geometry)
res_clc <- st_join(grd, clc) |>
  select(-idx)
nrow(grd) == nrow(res_clc)
qsave(res_clc, "dat/interim/misc_aoi/clc.qs", nthreads = 16L)

res <- res_clc |>
  # mutate(forest_cover = as.integer(res_wk$forest_cover)) |>
  mutate(clc = as.factor(CLC)) |>
  select(clc, forest_cover, geometry)
qsave(res, "dat/interim/misc_aoi/land_cover_full.qs", nthreads = 16L)
