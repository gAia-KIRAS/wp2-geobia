library(tidyverse)
library(sf)
library(stars)

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg")

dtm_tifs <- list.files("dat/interim/dtm_derivates/austria", full.names = TRUE)
