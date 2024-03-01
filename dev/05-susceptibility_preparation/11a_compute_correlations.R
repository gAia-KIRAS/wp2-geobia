print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("arrow")
  library("dplyr")
  library("tidyr")
  library("purrr")
  library("glue")
  library("qs")
})

source("dev/utils.R")

print(glue::glue("{Sys.time()} -- reading data"))
res <- read_ipc_file("dat/processed/carinthia_10m.arrow") |>
  select(-flow_path_length, -flow_width, -sca, -esa) |>
  select(where(is.numeric)) |>
  slice_sample(prop = 0.5) |>
  as.matrix()
gc()

glue("nrow before NA removal: {nrow(res)}")
res <- res[!rowSums(!is.finite(res)), ]
gc()
glue("nrow after NA removal: {nrow(res)}")

qsave(res, "dat/interim/sample_for_corr_comput.qs", nthreads = 16L)
# res <- qread("dat/interim/sample_for_corr_comput.qs", nthreads = 16L)

print(glue::glue("{Sys.time()} -- computing correlations"))
cn <- colnames(res)
corrs <- crossing(cn, cn)
corr <- map2_dbl(corrs$cn...1, corrs$cn...2, compute_corr, .progress = TRUE)
corrs$correlation <- corr
rm(res, cn, corr)
gc()

saveRDS(corrs, "dat/interim/correlations.rds")

print(glue::glue("{Sys.time()} -- done"))
