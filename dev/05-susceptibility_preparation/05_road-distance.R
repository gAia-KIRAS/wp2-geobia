library(dplyr)
library(sf)
library(nngeo)
library(qs)
library(tictoc)

ncores <- 64L

gip <- read_sf("dat/interim/gip/kaernten.gpkg") |>
  st_transform(3416) |>
  filter(FRC %in% c(0:11, 20, 21, 105, 106)) |>
  filter(BAUSTATUS == 5) |>
  rename(gip_id = ACTION_ID) |>
  select(gip_id, geom)

grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

# when using projected points, calculation is done using nabor::knn, a fast search method based on the libnabo C++ library
# setting parallel = ncores is not applicable
tic()
res <- st_nn(grd, gip, sparse = TRUE, k = 1, maxdist = 1000, progress = TRUE)
toc()

qsave(res, "dat/interim/misc_aoi/road_dist.qs", nthreads = ncores)
