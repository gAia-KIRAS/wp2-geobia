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
  select(gip_id = ACTION_ID, length = SHAPELENGTH, geom)
summary(gip$length)

tic()
gip_point <- gip |>
  st_cast("LINESTRING") |>
  st_line_sample(density = 0.2)
toc()
nrow(gip)
length(gip_point)

grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)
st_crs(gip_point) == st_crs(grd)

# when using projected points, calculation is done using nabor::knn, a fast search method based on the libnabo C++ library
# setting parallel = ncores is not applicable
tic()
res <- st_nn(grd, gip, sparse = TRUE, k = 1, maxdist = 1000, progress = TRUE)
toc()

qsave(res, "dat/interim/misc_aoi/road_dist.qs", nthreads = ncores)
