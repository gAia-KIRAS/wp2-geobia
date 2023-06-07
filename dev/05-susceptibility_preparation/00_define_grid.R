library(dplyr)
library(sf)
library(stars)
library(qs)

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

grd <- read_stars("dat/interim/dtm_derivates/austria/dtm_orig/dtm_austria.tif") |>
  st_set_crs(3416) |>
  st_crop(aoi) |>
  st_as_sf(as_points = TRUE)
colnames(grd)[1] <- "idx"
grd$idx <- rep(1L, nrow(grd))

qsave(grd, "dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 16L)

ch <- st_convex_hull(st_union(grd))
write_sf(ch, "dat/interim/aoi/gaia_ktn_grid.gpkg")
