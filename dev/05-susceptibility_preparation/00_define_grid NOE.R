library(dplyr)
library(sf)
library(stars)
library(qs)

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)

aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea.shp")  %>% # shp information of the region 
  st_transform(3416)

# make a new part for it
# nrow: 57,842,689
grd <- read_stars("wp2-geobia/dat/interim/dtm/dtm_austria.tif", proxy = FALSE) %>%
  st_set_crs(3416) %>%
  st_crop(aoi) %>%
  st_as_sf(as_points = TRUE)
colnames(grd)[1] <- "idx"
grd$idx <- rep(1L, nrow(grd))

grd <- read_stars("") # read in the cut tif and crop etc (what given above)


qsave(grd, "wp2-geobia/dat/interim/aoi/gaia_neo_grid.qs", nthreads = 64L)


#ch <- st_convex_hull(st_union(grd))
#write_sf(ch, "dat/interim/aoi/gaia_ktn_grid.gpkg")
