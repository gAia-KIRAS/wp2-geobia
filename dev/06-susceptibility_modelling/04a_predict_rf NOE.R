# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# predict random forest model
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("mlr3")
  library("ranger")
  library("arrow")
  library("dplyr")
  library("glue")
  library("sf")
  library("qs")
  library("tidyr")
})

ncores <- 28L

read_dat <- function(x) {
  read_ipc_file(x) %>%
    tidyr::drop_na() %>%
    mutate(across(x:y, as.integer))
}

predict_rf <- function(model, newdata) {
  model$predict_newdata(newdata) %>%
    as.data.table() %>%
    dplyr::select(truth, response, prob = prob.TRUE) %>%
    bind_cols(newdata %>% dplyr::select(x, y))
}

predict_ensemble <- function(ensemble, data) {
  lapply(ensemble, predict_rf, newdata = data) %>%
    bind_rows(.id = "iteration") %>%
    group_by(x, y) %>%
    summarize(mean_susc = mean(prob), sd_susc = sd(prob), .groups = "drop") %>%
    ungroup() %>%
    st_as_sf(coords = c("x", "y"), crs = 3416)
}

print(glue::glue("{Sys.time()} -- reading models"))
rf_mods <- readRDS("wp2-geobia/dat/interim/random_forest/ranger_mbo.rds")

# print(glue::glue("{Sys.time()} -- reading positive chunk"))
# pos_dat <- read_dat("dat/processed/chunks/pos/carinthia_slides.arrow")

# print(glue::glue("{Sys.time()} -- predicting positive chunk"))
# predict_ensemble(rf_mods, pos_dat) %>%
#   qsave("dat/processed/prediction/pos.qs", nthreads = 32L)

# print(glue::glue("{Sys.time()} -- working on negative chunks"))
# neg_lst <- list.files("dat/processed/chunks/neg", recursive = TRUE, full.names = TRUE)

# working on chunks #To DO next
print(glue::glue("{Sys.time()} -- working on chunks"))
chk_lst <- list.files("wp2-geobia/dat/processed/chunks/all", recursive = TRUE, full.names = TRUE)
for (f in chk_lst) {
  partition <- gsub("=", "", stringr::str_extract(f, "partition=[0-9]+"))
  print(glue::glue("{Sys.time()} .... processing {partition}"))
  outfile <- glue("wp2-geobia/dat/processed/prediction/random_forest/chunk_{partition}.qs")
  if (!file.exists(outfile)) {
    tmp <- read_dat(f) %>%
    drop_na()
    predict_ensemble(rf_mods, tmp) %>%
      qsave(outfile, nthreads = ncores)
  }
}

# for NOE no chunks but full dataset
print(glue::glue("{Sys.time()} -- reading data"))
dat_iters <- read_dat("wp2-geobia/dat/processed/gaia_noe_balanced_iters.arrow") #wrong, this is balanced data set, i need to predict on the full dataset

# full data set
dat_iters_arrow <- arrow::read_feather("wp2-geobia/dat/processed/noe_10m.arrow")

# dat_iters <- arrow::read_parquet("wp2-geobia/dat/processed/noe_10m.parquet")

dat_iters_arrow_cld <- drop_na(dat_iters_arrow)
print(glue::glue("{Sys.time()} -- predicting"))
predict_ensemble(rf_mods, dat_iters_arrow_cld) %>%
  qsave("wp2-geobia/dat/processed/prediction/random_forest/random_forest_prediction.qs", nthreads = ncores)

