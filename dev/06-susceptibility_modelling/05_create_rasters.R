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

print(glue::glue("{Sys.time()} -- loading data"))

mod_type <- "random_forest"
# mod_type <- "earth"
# mod_type <- "earth_esa"

fl_preds <- list.files(glue("dat/processed/prediction/{mod_type}"), full.names = TRUE)
res <- lapply(fl_preds, qread, nthreads = 16L) |>
  bind_rows()
print(glue::glue("{Sys.time()} -- saving full prediction dataframe"))
qsave(res, glue("dat/processed/prediction/{mod_type}_prediction_mean_sd_sf.qs"), nthreads = 16L)

# res <- qread(glue("dat/processed/prediction/{mod_type}_prediction_mean_sd_sf.qs"), nthreads = 16L)
# > object.size(res) |> format("auto")
# [1] "24 Gb"

print(glue::glue("{Sys.time()} -- rasterizing mean"))
res |>
  select(mean_susceptibility = mean_susc, geometry) |>
  st_rasterize() |>
  write_stars(glue("dat/reporting/susceptibility_mean_{mod_type}.tif"), type = "Float32", NA_value = -1)
cmd1 <- glue("gdalwarp -cutline dat/raw/aoi/gaia_aoi_ktn_3416.gpkg -crop_to_cutline -overwrite dat/reporting/susceptibility_mean_{mod_type}.tif dat/reporting/susceptibility_mean_{mod_type}_cut.tif")
system(command = cmd1)

print(glue::glue("{Sys.time()} -- rasterizing sd"))
res |>
  select(sd_susceptibility = sd_susc, geometry) |>
  st_rasterize() |>
  write_stars(glue("dat/reporting/susceptibility_sd_{mod_type}.tif"), type = "Float32", NA_value = -1)
cmd2 <- glue("gdalwarp -cutline dat/raw/aoi/gaia_aoi_ktn_3416.gpkg -crop_to_cutline -overwrite dat/reporting/susceptibility_sd_{mod_type}.tif dat/reporting/susceptibility_sd_{mod_type}_cut.tif")
system(command = cmd2)
