# load packages
library("dplyr")
library("sf")
library("stars")

# create polygon somewhere in Oberkärnten
test_aoi <- c(
  435800, 443000, 443000, 435800, 435800,
  200500, 200500, 210000, 210000, 200500
) %>%
  matrix(ncol = 2) %>%
  list() %>%
  st_polygon() %>%
  st_sfc(crs = 31258)

# export result
st_write(test_aoi, "dat/interim/aoi/test_area.gpkg")

# full dtm
dtm <- read_stars("dat/raw/dtm/dtm_ktn/ALS_DGM_1m.img")
st_crs(dtm) <- 31258

# crop to small aoi for testing purposes
dtm_aoi <- dtm %>%
  st_crop(test_aoi)

write_stars(dtm_aoi, "dat/interim/dtm/test_aoi_ktn.tif")

# gdalwarp -dstnodata -9999 -cutline dat/interim/aoi/test_area.gpkg dat/raw/dtm/dtm_ktn/ALS_DGM_1m.img dat/interim/dtm/test_aoi_ktn.tif
