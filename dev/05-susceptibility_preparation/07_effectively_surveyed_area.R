library(tidyverse)
library(sf)
library(stars)
library(glue)
library(qs)

source("dev/utils.R")

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

esa <- read_stars("dat/interim/effectively_surveyed_area/res_distance_rescaled_binary.tif") |>
  #st_crop(aoi) |>
  st_as_sf(as_points = TRUE)
st_crs(esa) # 3416
colnames(esa)[1] <- "esa"
esa <- esa |> mutate(esa = as.integer(esa))

qsave(esa, "dat/interim/misc_aoi/esa.qs", nthreads = 16L)
