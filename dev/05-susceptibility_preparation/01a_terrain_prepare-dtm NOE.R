library(tidyverse)
library(sf)
library(stars)
library(glue)
library(qs)
library(qdap)
library(glue)

source("dev/utils.R")

aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea.shp")  %>% # shp information of the region 
  st_transform(3416)

dtm_list_full <- list.files("wp2-geobia/dat/output/austria", full.names = TRUE) #location for the /output/austria
drops <- c(
  "aspect.tif", "aspect-rad", "aspect-cos", "aspect-sin",
  "catchment-area", "channel-network", "sinks-filled",
  "slope-rad"
)

dtm_list <- exclude(dtm_list_full, drops)

#test_raster <- read_stars("wp2-geobia/dat/output/austria/dhm_at_lamb_10m_2018_PTO.tif")

create_subset <- function(raster, crop = aoi) {
  index_name <- basename(raster)
  index_name <- gsub("^(dhm_at_lamb_10m_2018_)(.*)(.tif)", "\\2", index_name)
  outfile <- glue("dat/interim/dtm_aoi/tmp_qs/{index_name}.qs")
  if (file.exists(outfile)) {
    print(glue("{Sys.time()} -- Skipping {index_name} (file exists)"))
  } else {
    print(glue("{Sys.time()} -- Working on {index_name}"))
    tmp <- read_stars(raster)
    st_crs(tmp) <- 3416
    out <- st_crop(tmp, crop)
    res <- st_as_sf(out, as_points = TRUE)
    colnames(res)[1] <- index_name
    qsave(res, outfile, nthreads = 64L)
  }
}

lapply(dtm_list_full, create_subset)
