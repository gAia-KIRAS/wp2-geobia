library(sf)
library(stars)

aoi <- st_read("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_union() |>
  st_transform(3416) |>
  st_make_valid(geos_method = "valid_structure")
st_write(aoi, "dat/interim/aoi/gaia_projektgebiet_ktn_union_3416.gpkg", delete_dsn = TRUE)

dtm <- read_stars("dat/interim/dtm/dtm_austria.tif")

dtm |>
  st_crop(aoi) |>
  write_stars("dat/interim/dtm_aoi/dtm_austria_carinthia.tif")
