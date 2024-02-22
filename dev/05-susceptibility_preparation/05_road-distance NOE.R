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

fix_empty <- function(x) {
  if (length(x) == 0) {
    x <- NA
  }
  return(x)
}

print(glue("{Sys.time()} -- loading GIP"))
gip <- read_sf("wp2-geobia/dat/interim/gip/gip_noe.gpkg") %>%
  st_transform(3416) %>%
  filter(FRC %in% c(0:11, 20, 21, 105, 106)) %>%
  filter(BAUSTATUS == 5) %>%
  select(gip_id = ACTION_ID, length = SHAPELENGTH, geom)
print(glue("    summary of GIP linestring lengths:"))
summary(gip$length)

print(glue("{Sys.time()} -- sampling points"))
tic()
gip_point <- gip %>%
  st_cast("LINESTRING") %>%
  st_line_sample(density = 0.2)
gip_point <- gip_point[!st_is_empty(gip_point)]
gip_point <- st_cast(gip_point, "POINT")
toc()
print(glue("    sampled {length(gip_point)} points on {nrow(gip)} linestrings"))

print(glue("{Sys.time()} -- loading grid"))
tic()
grd <- qread("wp2-geobia/dat/interim/aoi/gaia_neo_grid.qs", nthreads = ncores)
toc()
stopifnot(st_crs(gip_point) == st_crs(grd))

print(glue("{Sys.time()} -- searching for nearest neightbors"))
# when using projected points, calculation is done using nabor::knn, a fast search method based on the libnabo C++ library
# setting parallel = ncores is not applicable
tic()
res <- st_nn(grd, gip_point, sparse = TRUE, k = 1, maxdist = 500, returnDist = TRUE, progress = TRUE)
toc()

print(glue("{Sys.time()} -- saving nested list"))
qsave(res, "wp2-geobia/dat/interim/misc_aoi/road_dist_list.qs", nthreads = ncores)

print(glue("{Sys.time()} -- creating clean tibble"))
tic()
nn <- sapply(res$nn, fix_empty)
dist <- sapply(res$dist, fix_empty)
stopifnot(length(nn) == length(dist))
out <- tibble(grd_id = 1:length(nn), nn, dist) %>%  # nolint
  mutate(dist = if_else(is.na(dist), 500, dist))
toc()

print(glue("    check if dataframe sizes match"))
nrow(grd) == nrow(out)

nona <- nrow(out %>% tidyr::drop_na())
print(glue("    number of pixels (percent) with roads within 500 m"))
print(glue("{nona} ({round((nona / nrow(out)*100), 2)} %)"))

print(glue("{Sys.time()} -- saving tibble"))
qsave(out, "wp2-geobia/dat/interim/misc_aoi/road_dist.qs", nthreads = ncores)

print(glue("{Sys.time()} -- DONE"))
