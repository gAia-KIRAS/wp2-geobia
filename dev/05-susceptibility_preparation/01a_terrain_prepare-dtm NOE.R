library(tidyverse)
library(sf)
library(stars)
library(glue)
library(qs)
#library(qdap)

source("wp2-geobia/dev/utils.R")

aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea.shp")  %>% # shp information of the region 
  st_transform(3416)

dtm_list_full <- list.files("wp2-geobia/dat/output/austria", full.names = TRUE) #location for the /output/austria
drops <- c(
  "aspect.tif", "aspect-rad", "aspect-cos", "aspect-sin",
  "catchment-area", "channel-network", "sinks-filled",
  "slope-rad"
)

dtm_list <- exclude(dtm_list_full, drops)

create_subset <- function(raster, crop = aoi) {
  index_name <- basename(raster)
  index_name <- gsub("^(dhm_at_lamb_10m_2018_)(.*)(.tif)", "\\2", index_name)
  outfile <- glue("wp2-geobia/dat/interim/dtm_aoi/tmp_qs/{index_name}.qs")
  if (file.exists(outfile)) {
    print(glue("{Sys.time()} -- Skipping {index_name} (file exists)"))
  } else {
    print(glue("{Sys.time()} -- Working on {index_name}"))
    tmp <- read_stars(raster, proxy = FALSE)
    tmp <- st_set_crs(tmp, 3416)
    out <- st_crop(tmp, crop)
    res <- st_as_sf(out, as_points = TRUE)
    colnames(res)[1] <- index_name
    qsave(res, outfile, nthreads = 64L)
  }
}

lapply(dtm_list, create_subset)

# aspect dtm
create_subset_aspect <- function(raster, crop = aoi) {
  index_name <- basename(raster)
  index_name <- gsub("^(dtm_austria_)(.*)(.tif)", "\\2", index_name)
  outfile <- glue("wp2-geobia/dat/interim/dtm_aoi/tmp_qs/{index_name}.qs")
  if (file.exists(outfile)) {
    print(glue("{Sys.time()} -- Skipping {index_name} (file exists)"))
  } else {
    print(glue("{Sys.time()} -- Working on {index_name}"))
    tmp <- read_stars(raster, proxy = FALSE)
    tmp <- st_set_crs(tmp, 3416)
    out <- st_crop(tmp, crop)
    res <- st_as_sf(out, as_points = TRUE)
    colnames(res)[1] <- index_name
    qsave(res, outfile, nthreads = 60L)
  }
}
raster <- "wp2-geobia/dat/output/austria/dtm_austria_aspect-arctan2.tif"
lapply(raster, create_subset_aspect)
