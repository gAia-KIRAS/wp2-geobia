library(tidyverse)
library(sf)
library(stars)

source("dev/utils.R")

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg")

dtm_list_full <- list.files("dat/interim/dtm_derivates/austria/dtm_orig", full.names = TRUE)
drops <- c(
  "aspect.tif", "aspect-rad", "aspect-cos", "aspect-sin",
  "catchment-area", "channel-network", "sinks-filled",
  "slope-rad"
)

dtm_list <- exclude(dtm_list_full, drops)
