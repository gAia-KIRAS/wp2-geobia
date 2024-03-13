# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# create rasters from tibbles
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("sf")
  library("dplyr")
  library("stars")
  library("glue")
  library("qs")
})
library("raster")

print(glue::glue("{Sys.time()} -- loading data"))

ncores <- 28L

mod_type <- "random_forest"
# mod_type <- "earth"
# mod_type <- "earth_esa"

fl_preds <- list.files(glue("wp2-geobia/dat/processed/prediction/{mod_type}"), full.names = TRUE)
res <- lapply(fl_preds, qread, nthreads = ncores) %>%
  bind_rows()
print(glue::glue("{Sys.time()} -- saving full prediction dataframe"))
qsave(res, glue("wp2-geobia/dat/processed/prediction/{mod_type}_prediction_mean_sd_sf.qs"), nthreads = ncores)

res <- qread(glue("wp2-geobia/dat/processed/prediction/{mod_type}_prediction_mean_sd_sf.qs"), nthreads = ncores)
object.size(res) %>% format("auto")
# [1] "24 Gb" carinthian file
# [1] "12.4 Gb" NOE file

print(glue::glue("{Sys.time()} -- rasterizing mean"))
res %>%
  dplyr::select(mean_susceptibility = mean_susc, geometry) %>%
  st_rasterize() %>%
  write_stars(glue("wp2-geobia/dat/reporting/susceptibility_mean_{mod_type}.tif"), type = "Float32", NA_value = -1)
# cmd1 <- glue("gdalwarp -cutline wp2-geobia/dat/interim/aoi/NOE_gaiaArea_3416.shp -crop_to_cutline -overwrite wp2-geobia/dat/reporting/susceptibility_mean_{mod_type}.tif wp2-geobia/dat/reporting/susceptibility_mean_{mod_type}_cut.tif")
# system(command = cmd1)

## TO DO: check if it's cut or it needs to be cut to the area

# # cutting (not needed, it's already cropped to the area)
# raster <- raster(glue("wp2-geobia/dat/reporting/susceptibility_mean_{mod_type}.tif"))
# # to do: find a file with the outline for chosen area to cut
# aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea_dissolved.shp")  %>% 
#   st_transform(3416)
# cropped_res <- mask(raster, aoi)
# writeRaster(cropped_res, glue("wp2-geobia/dat/reporting/susceptibility_mean_{mod_type}_cut.tif"))


print(glue::glue("{Sys.time()} -- rasterizing sd"))
res %>%
  select(sd_susceptibility = sd_susc, geometry) %>%
  st_rasterize() %>%
  write_stars(glue("wp2-geobia/dat/reporting/susceptibility_sd_{mod_type}.tif"), type = "Float32", NA_value = -1)
# cmd2 <- glue("gdalwarp -cutline dat/raw/aoi/gaia_aoi_ktn_3416.gpkg -crop_to_cutline -overwrite dat/reporting/susceptibility_sd_{mod_type}.tif dat/reporting/susceptibility_sd_{mod_type}_cut.tif")
# system(command = cmd2)

## TO DO: check if it's cut or it needs to be cut to the area
