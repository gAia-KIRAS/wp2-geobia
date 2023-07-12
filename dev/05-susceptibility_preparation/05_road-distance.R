suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(sf)
  library(nngeo)
  library(qs)
  library(glue)
  library(tictoc)
})

ncores <- 64L

simplify_nn <- function(nn, dist) {
  if (length(nn) == 0) {
    out <- tibble(nn = as.integer(NA), dist = as.double(NA))
  } else {
    out <- tibble(nn = nn, dist = dist)
  }
  return(out)
}

print(glue("{Sys.time()} -- loading GIP"))
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
  st_line_sample(density = 0.2)
gip_point <- gip_point[!st_is_empty(gip_point)]
gip_point <- st_cast(gip_point, "POINT")
toc()
print(glue("    sampled {length(gip_point)} points on {nrow(gip)} linestrings"))

print(glue("{Sys.time()} -- loading grid"))
tic()
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)
toc()
stopifnot(st_crs(gip_point) == st_crs(grd))

print(glue("{Sys.time()} -- searching for nearest neightbors"))
# when using projected points, calculation is done using nabor::knn, a fast search method based on the libnabo C++ library
# setting parallel = ncores is not applicable
tic()
res <- st_nn(grd, gip_point, sparse = TRUE, k = 1, maxdist = 500, returnDist = TRUE, progress = TRUE)
toc()

print(glue("{Sys.time()} -- saving nested list"))
qsave(res, "dat/interim/misc_aoi/road_dist_list.qs", nthreads = ncores)

print(glue("{Sys.time()} -- creating clean tibble"))
tic()
out <- map2(.x = res$nn, .y = res$dist, .f = simplify_nn) |>
  bind_rows(.id = "grd_id") |>
  mutate(grd_id = as.integer(grd_id))
toc()

print(glue("    check if dataframe sizes match"))
nrow(grd) == nrow(out)

print(glue("{Sys.time()} -- saving tibble"))
qsave(out, "dat/interim/misc_aoi/road_dist.qs", nthreads = ncores)

print(glue("{Sys.time()} -- DONE"))
