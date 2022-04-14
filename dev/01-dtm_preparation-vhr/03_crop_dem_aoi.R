# load packages
library("dplyr")
library("sf")
library("stars")
library("glue")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# AOI for testing purposes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# create polygon somewhere in Oberkärnten
xmin <- 436350
xmax <- 439730
ymin <- 200200
ymax <- 202420

test_aoi <- c(
  xmin, xmax, xmax, xmin, xmin,
  ymin, ymin, ymax, ymax, ymin
) %>%
  matrix(ncol = 2) %>%
  list() %>%
  st_polygon() %>%
  st_sfc(crs = 31258)

# export result
st_write(test_aoi, "dat/interim/aoi/test_area.gpkg")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# AOI Carinthia
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# predefined AOI polygon
carinthia <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg")

# full dtm
dtm <- read_stars("dat/raw/dtm/dtm_ktn/ALS_DGM_1m.img")
st_crs(dtm) <- 31258

# crop to small aoi for testing purposes
dtm %>%
  st_crop(test_aoi) %>%
  write_stars("dat/interim/dtm/test_aoi_ktn.tif")

# crop to regions
for (region in carinthia$name) {
  print(glue("{Sys.time()} -- Working on region '{region}'"))
  outfile <- glue("dat/interim/dtm/dtm_carinthia_{region}.tif")
  tmp_aoi <- carinthia %>%
    filter(name == region)
  if (file.exists(outfile)) {
    cat("  » Area cropped already\n")
  } else {
    cat("  » Cropping\n")
    dtm %>%
      st_crop(tmp_aoi) %>%
      write_stars(outfile)
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# AOI Lower Austria
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# TODO

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# gdalwarp -dstnodata -9999 -cutline dat/interim/aoi/test_area.gpkg dat/raw/dtm/dtm_ktn/ALS_DGM_1m.img dat/interim/dtm/test_aoi_ktn.tif
