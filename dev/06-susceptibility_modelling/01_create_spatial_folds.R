# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# create spatial folds for CV
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library(mlr3)
  library(mlr3spatiotempcv)
  library(dplyr)
  library(qs)
  library(glue)
})

source("dev/utils.R")

ncores <- 32L

wall("{Sys.time()} -- loading data")
dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores) |>
  mutate(iter = as.integer(iter))

get_spatial_folds <- function(dat, iteration) {
  tmp <- dat |>
    filter(iter == iteration) |>
    mutate(slide = as.factor(slide)) |>
    select(-iter)

  # define task
  task <- TaskClassifST$new(
    id = glue("carinthia-{iteration}"),
    backend = tmp,
    target = "slide",
    positive = "TRUE",
    coordinate_names = c("x", "y"),
    crs = "epsg:3416",
    coords_as_features = FALSE
  )

  # resampling
  resampling <- rsmp("spcv_coords", folds = 5)
  resampling$instantiate(task)

  # get spatial folds
  assigned_folds <- resampling$instance |>
    as_tibble()

  # prepare output data frame
  tmp <- tmp |>
    as_tibble() |>
    tibble::rowid_to_column("row_id") |>
    left_join(assigned_folds, by = "row_id") |>
    mutate(fold = as.factor(fold)) %>%
    select(slide:lithology, fold, x, y)

  # result
  return(tmp)
}

lapply(unique(dat$iter), get_spatial_folds, dat = dat) |>
  bind_rows(.id = "iter") |>
  mutate(iter = as.integer(iter)) |>
  qsave("dat/processed/gaia_ktn_balanced_iters_spatialfolds.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
