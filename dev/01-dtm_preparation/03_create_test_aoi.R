# load packages
library("dplyr")
library("sf")

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
st_write(extents, "dat/interim/aoi/test_area.gpkg")
