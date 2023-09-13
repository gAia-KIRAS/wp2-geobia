print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(qs)
  library(arrow)
  library(glue)
})

source("dev/utils.R")

ncores <- 32L

wall("{Sys.time()} -- loading data sets")
absence_grd <- qread("dat/interim/aoi/gaia_ktn_absence_grid.qs", nthreads = ncores) |>
  select(neg_sample)

full <- read_ipc_file("dat/processed/carinthia_10m.arrow") |>
  bind_cols(absence_grd) |>
  drop_na()
rm(absence_grd)
gc()

wall("{Sys.time()} -- subsetting positive instances")
pos_all <- full |>
  filter(slide == TRUE) |>
  select(-neg_sample)

wall("{Sys.time()} -- subsetting negative instances")
neg_all <- full |>
  filter(neg_sample == TRUE) |>
  select(-neg_sample)

create_balanced_subset <- function(seed, df_neg, df_pos) {
  set.seed(seed)
  tmp <- slice_sample(df_neg, n = nrow(df_pos), weight_by = slope, replace = FALSE)
  out <- bind_rows(tmp, df_pos)
  return(out)
}

lapply(1:10, create_balanced_subset, df_neg = neg_all, df_pos = pos_all) |>
  bind_rows(.id = "iter") |>
  qsave("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")
