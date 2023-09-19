# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# tune and train random forest
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
})

read_dat <- function(x) {
  read_ipc_file(x) |>
    tidyr::drop_na() |>
    mutate(across(x:y, as.integer))
}

predict_rf <- function(model, newdata) {
  model$predict_newdata(newdata) |>
    as.data.table() |>
    select(truth, response, prob = prob.TRUE) |>
    bind_cols(newdata |> select(x, y))
}

predict_ensemble <- function(ensemble, data) {
  lapply(ensemble, predict_rf, newdata = data) |>
    bind_rows(.id = "iteration") |>
    group_by(x, y) |>
    summarize(mean_susc = mean(prob), sd_susc = sd(prob)) |>
    ungroup() |>
    st_as_sf(coords = c("x", "y"), crs = 3416)
}

print(glue::glue("{Sys.time()} -- reading models"))
rf_mods <- readRDS("dat/interim/random_forest/ranger_mbo.rds")

print(glue::glue("{Sys.time()} -- reading positive chunk"))
pos_dat <- read_dat("dat/processed/chunks/pos/carinthia_slides.arrow")

print(glue::glue("{Sys.time()} -- predicting positive chunk"))
predict_ensemble(rf_mods, pos_dat) |>
  qsave("dat/processed/prediction/pos.qs", nthreads = 32L)

print(glue::glue("{Sys.time()} -- working on negative chunks"))
neg_lst <- list.files("dat/processed/chunks/neg", recursive = TRUE, full.names = TRUE)
for (f in neg_lst) {
  partition <- gsub("=", "", stringr::str_extract(f, "partition=[0-9]"))
  print(glue::glue(".... processing {partition}"))
  neg_tmp <- read_dat(f)
  neg_pred <- predict_ensemble(rf_mods, neg_tmp)
  qsave(neg_pred, "dat/processed/prediction/neg_{partition}.qs", nthreads = 32L)
}
