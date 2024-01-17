library(sf)
library(stars)

st_read("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_union() |>
  st_transform(3416) |>
  st_make_valid(geos_method = "valid_structure") |>
  st_write("dat/interim/aoi/gaia_projektgebiet_ktn_union_3416.gpkg", delete_dsn = TRUE)

