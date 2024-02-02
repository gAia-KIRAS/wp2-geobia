# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# tune and train random forest
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("mlr3")
  library("mlr3learners")
  library("mlr3tuning")
  library("mlr3mbo")
  library("mlr3spatiotempcv")
  library("ranger")
  library("dplyr")
  library("qs")
  library("glue")
})

ncores <- 16L

source("dev/utils.R")

ids <- glue("iteration-{sprintf('%02d', 1:10)}")

wall("{Sys.time()} -- reading data")
dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores) |>
  select(-elevation, -flow_path_length, -flow_width, -sca) |>
  mutate(slide = as.factor(slide)) |>
  group_by(iter) |>
  group_split(.keep = FALSE)

# tune random forest w/ mlr3mbo
wall("{Sys.time()} -- tuning rf")
dat_rf <- lapply(dat, random_forest)
names(dat_rf) <- ids
saveRDS(dat_rf, "dat/interim/random_forest/ranger_mbo.rds")

# estimate performance with nested resampling
wall("{Sys.time()} -- estimating performance via nested resampling")
dat_rr <- lapply(dat, nested_resampling)
names(dat_rr) <- ids
saveRDS(dat_rr, "dat/interim/random_forest/ranger_nested_resampling.rds")

# get metrics
wall("{Sys.time()} -- obtaining metrics")
met <- lapply(dat_rr, get_score) |>
  bind_rows(.id = "key")

# summarize across all single folds
met |>
  summarize(
    min_score = min(classif.ce),
    mean_score = mean(classif.ce),
    max_score = max(classif.ce)
  )

# aggregate all folds per iteration and summarize across all iterations
met |>
  group_by(iteration) |>
  summarize(classif.ce = mean(classif.ce)) |>
  ungroup() |>
  summarize(
    min_score = min(classif.ce),
    mean_score = mean(classif.ce),
    max_score = max(classif.ce)
  )

lapply(dat_rr, get_inner_tuning) |>
  bind_rows(.id = "key")
