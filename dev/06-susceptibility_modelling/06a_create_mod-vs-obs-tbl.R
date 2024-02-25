# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# mod vs obs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("sf")
  library("dplyr")
  library("tidyr")
  library("glue")
  library("qs")
})

source("dev/utils.R")

print(glue::glue("{Sys.time()} -- loading data"))

ncores <- 16L

mod_type <- "random_forest"
# mod_type <- "earth"
# mod_type <- "earth_esa"

obs <- qread("dat/interim/misc_aoi/inventory.qs", nthreads = ncores) |>
  as_tibble() |>
  mutate(x = as.integer(x), y = as.integer(y))
pred <- qread(glue("dat/processed/prediction/{mod_type}_prediction_mean_sd_sf.qs"), nthreads = ncores) |>
  sfc_as_cols() |>
  st_drop_geometry() |>
  mutate(x = as.integer(x), y = as.integer(y))

res <- left_join(obs, pred, by = c("x", "y")) |>
  drop_na()

nrow(obs) - nrow(pred)
nrow(res) == nrow(pred)

# object.size(res) |> format("auto")
# [1] "1.5 Gb"

qsave(res, glue("dat/processed/prediction/mod-vs-obs/{mod_type}.qs"), nthreads = ncores)
