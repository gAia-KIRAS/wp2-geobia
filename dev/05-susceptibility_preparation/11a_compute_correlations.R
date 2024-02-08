print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("arrow")
  library("dplyr")
  library("tidyr")
  library("purrr")
})

print(glue::glue("{Sys.time()} -- reading data"))
res <- read_ipc_file("dat/processed/carinthia_10m.arrow") |>
  select(-flow_path_length, -flow_width, -sca, -esa, -x, -y) |>
  select(where(is.numeric)) |>
  slice_sample(prop = 0.5) |>
  as.matrix()

# compute corr
fastcor <- function(x) {
  1 / (NROW(x) - 1) * crossprod(scale(x, TRUE, TRUE))
}


print(glue::glue("{Sys.time()} -- computing correlations"))
compute_corr <- function(cn1, cn2, dat = res) {
  if (cn1 == cn2) {
    out <- 1
  } else {
    out <- cor(dat[, cn1], dat[, cn2])
  }
  return(out)
}

cn <- colnames(res)
corrs <- crossing(cn, cn)
corr <- map2_dbl(corrs$cn...1, corrs$cn...2, compute_corr, .progress = TRUE)
corrs$corr <- corr
rm(res, cn, corr)
gc()

saveRDS(corrs, "dat/interim/correlations.rds")

print(glue::glue("{Sys.time()} -- done"))
