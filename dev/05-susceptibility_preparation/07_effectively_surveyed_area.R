library(tidyverse)
library(sf)
library(stars)
library(glue)
library(qs)

source("dev/utils.R")

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

esa <- read_stars("dat/interim/effectively_surveyed_area/res_distance_rescaled_binary_clipped.tif") |>
  # st_crop(aoi) |>
  st_as_sf(as_points = TRUE) |>
  rename(esa = res_distance_rescaled_binary_clipped.tif) |>
  mutate(esa = as.integer(esa))

st_crs(esa) # 3416


qsave(esa, "dat/interim/misc_aoi/esa_incomplete.qs", nthreads = 16L)

# complete grid
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)
esa <- qread("dat/interim/misc_aoi/esa.qs", nthreads = ncores)
chk <- st_geometry(grd) %in% st_geometry(esa)
table(chk)
# FALSE     TRUE
#     7 57842682
# idx <- which(!chk)
# which(!chk) |> dput()
# idx <- c(1L, 2L, 3L, 4L, 57842687L, 57842688L, 57842689L)
# grd |> slice(idx)
add <- grd |>
  slice(which(!chk)) |>
  mutate(esa = 0L) |>
  select(-idx)

res <- add |>
  slice(1:4) |>
  bind_rows(esa) |>
  bind_rows(add |> slice(5:7))
stopifnot(nrow(res) == nrow(grd))
stopifnot(identical(st_coordinates(res), st_coordinates(grd)))

qsave(res, "dat/interim/misc_aoi/esa.qs", nthreads = 16L)
