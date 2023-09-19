# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# tune and train random forest
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
# fl_preds <- list.files("dat/processed/prediction", full.names = TRUE)
# res <- lapply(fl_preds, qread, nthreads = 32L) |>
#   bind_rows()
# qsave(res, "dat/processed/prediction_mean_sd_sf.qs", nthreads = 32L)
res <- qread("dat/processed/prediction_mean_sd_sf.qs", nthreads = 32L)
# > object.size(res) |> format("auto")
# [1] "24 Gb"

print(glue::glue("{Sys.time()} -- rasterizing mean"))
res |>
  select(mean_susceptibility = mean_susc, geometry) |>
  st_rasterize() |>
  write_stars("dat/reporting/susceptibility_mean.tif", type = "Float32", NA_value = -1)
# gdalwarp -cutline dat/raw/aoi/gaia_projektgebiet_ktn.gpkg -crop_to_cutline dat/reporting/susceptibility_mean.tif dat/reporting/susceptibility_mean_cut.tif

print(glue::glue("{Sys.time()} -- rasterizing sd"))
res |>
  select(sd_susceptibility = sd_susc, geometry) |>
  st_rasterize() |>
  write_stars("dat/reporting/susceptibility_sd.tif", type = "Float32", NA_value = -1)
# gdalwarp -cutline dat/raw/aoi/gaia_projektgebiet_ktn.gpkg -crop_to_cutline dat/reporting/susceptibility_sd.tif dat/reporting/susceptibility_sd_cut.tif
