# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# create rasters from parquet
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("sf")
  library("dplyr")
  library("stars")
  library("glue")
  library("arrow")
})

print(glue::glue("{Sys.time()} -- loading data"))

res <- read_parquet("dat/processed/prediction/noe_predictions.parquet") |>
  select(susceptibility, uncertainty, x, y) |>
  mutate(x = as.integer(x), y = as.integer(y)) |>
  st_as_sf(coords = c("x", "y"), crs = 3416)

print(glue::glue("{Sys.time()} -- rasterizing"))
out <- st_rasterize(res) |>
  merge(name = "attributes")

print(glue::glue("{Sys.time()} -- exporting geotiff"))
write_stars(out, layers = 1:2, glue("dat/reporting/susceptibility_noe.tif"), type = "Float32", NA_value = -1)
cmd <- glue("gdalwarp -cutline dat/raw/aoi/gaia_projektgebiet_noe/noe.gpkg -crop_to_cutline -overwrite dat/reporting/susceptibility_noe.tif dat/reporting/susceptibility_noe_cut.tif")
system(command = cmd)
