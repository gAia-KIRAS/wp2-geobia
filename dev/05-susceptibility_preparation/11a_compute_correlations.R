print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("arrow")
  library("dplyr")
  library("tidyr")
  library("purrr")
  library("glue")
  library("qs")
})

print(glue::glue("{Sys.time()} -- reading data"))
res <- read_ipc_file("dat/processed/carinthia_10m.arrow") |>
  select(-flow_path_length, -flow_width, -sca, -esa, -x, -y) |>
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
