# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ALE plots
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("mlr3verse")
  library("mlr3spatiotempcv")
  library("ranger")
  library("iml")
  library("dplyr")
  library("purrr")
  library("qs")
  library("arrow")
  library("glue")
  library("parallel")
  library("showtext")
})

source("dev/utils.R")

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

ncores <- 16L

glue("{Sys.time()} -- reading data")
# glue("{Sys.time()} --   ├─ full data")
# fulldat <- read_ipc_file("dat/processed/carinthia_10m.arrow", col_select = NULL, as_data_frame = TRUE, mmap = TRUE)

glue("{Sys.time()} --   ├─ balanced data")
dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores) |>
  select(-elevation, -flow_path_length, -flow_width, -sca, -esa) |>
  mutate(slide = as.factor(slide)) |>
  group_by(iter) |>
  group_split(.keep = FALSE)

task <- lapply(dat, as_task_classif_st, target = "slide", positive = "TRUE", coordinate_names = c("x", "y"), crs = "epsg:3416")

glue("{Sys.time()} --   └─ mbo")
rf_mods <- readRDS("dat/interim/random_forest/ranger_mbo.rds")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

features <- lapply(rf_mods, get_importance) |>
  bind_rows(.id = "id") |>
  mutate(id = gsub("iteration-", "", id)) |>
  group_by(index) |>
  mutate(index = as.character(index)) |>
  summarize(imp = mean(importance)) |>
  arrange(-imp) |>
  pull(index) |>
  head(10)

compute_effect <- function(featurename, predictor = predictor) {
  FeatureEffect$new(predictor, feature = featurename, method = "pdp+ice")$results
}

tmp <- list()
for (i in 1:length(rf_mods)) {
  print(glue("{format(Sys.time())} -- computing PDP and ICE | Iteration: {stringr::str_pad(i, 2, pad = '0')}"))
  lrn_rf <- rf_mods[[i]]
  dat_tmp <- dat[[i]]
  predictor <- Predictor$new(lrn_rf, data = dat_tmp, y = "slide")
  res <- mclapply(features, compute_effect, predictor = predictor, mc.cores = 16L)
  names(res) <- features
  tmp[[i]] <- res
}
rm(i, rf_mods, lrn_rf, dat_tmp, dat, predictor, res)
gc()

fin <- list()
for (feature in features) {
  print(glue("{format(Sys.time())} -- working on feature {feature}"))
  fin[[feature]] <- lapply(tmp, \(x) x[[feature]]) |>
    bind_rows(.id = "iteration") |>
    mutate(iteration = as.integer(iteration), .type = as.factor(.type)) |>
    as_tibble()
}

qsave(fin, "dat/interim/random_forest/pdp+ice.qs", nthreads = ncores)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
