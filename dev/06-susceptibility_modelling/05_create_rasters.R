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
fl_preds <- list.files("dat/processed/prediction", full.names = TRUE)
res <- lapply(fl_preds, qread, nthreads = 32L) |>
  bind_rows()

print(glue::glue("{Sys.time()} -- rasterizing mean"))
res |>
  select(mean_susceptibility = mean_susc, geometry) |>
  st_rasterize() |>
  write_stars("dat/proceassed/prediction/susceptibility_mean.tif")

print(glue::glue("{Sys.time()} -- rasterizing sd"))
res |>
  select(sd_susceptibility = sd_susc, geometry) |>
  st_rasterize() |>
  write_stars("dat/proceassed/prediction/susceptibility_mean.tif")
