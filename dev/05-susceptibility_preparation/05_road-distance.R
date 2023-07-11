suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(nngeo)
  library(qs)
  library(glue)
  library(tictoc)
})

print(glue("{Sys.time()} -- loading GIP"))
ncores <- 64L

gip <- read_sf("dat/interim/gip/kaernten.gpkg") |>
  st_transform(3416) |>
  filter(FRC %in% c(0:11, 20, 21, 105, 106)) |>
  filter(BAUSTATUS == 5) |>
  select(gip_id = ACTION_ID, length = SHAPELENGTH, geom)
print(glue("    summary of GIP linestring lengths:"))
summary(gip$length)

print(glue("{Sys.time()} -- sampling points"))
tic()
gip_point <- gip |>
  st_cast("LINESTRING") |>
  st_line_sample(density = 0.2) |>
  st_cast("POINT")
gip_point <- gip_point[!st_is_empty(gip_point)]
toc()
print(glue("    sampled {length(gip_point)} points on {nrow(gip)} linestrings"))

print(glue("{Sys.time()} -- loading grid"))
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)
stopifnot(st_crs(gip_point) == st_crs(grd))

print(glue("{Sys.time()} -- searching for nearest neightbors"))
# when using projected points, calculation is done using nabor::knn, a fast search method based on the libnabo C++ library
# setting parallel = ncores is not applicable
tic()
res <- st_nn(grd, gip, sparse = TRUE, k = 1, maxdist = 500, returnDist = TRUE, progress = TRUE)
toc()

qsave(res, "dat/interim/misc_aoi/road_dist.qs", nthreads = ncores)
