# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# tune and train random forest
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("mlr3")
  library("mlr3extralearners")
  library("mlr3tuning")
  library("mlr3mbo")
  library("mlr3spatiotempcv")
  library("earth")
  library("dplyr")
  library("qs")
  library("glue")
})

ncores <- 16L

source("dev/utils.R")

ids <- glue("iteration-{sprintf('%02d', 1:10)}")

wall("{Sys.time()} -- reading data")
dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores) |>
  select(-elevation, -flow_path_length, -flow_width, -sca, -esa) |>
  mutate(slide = as.factor(slide)) |>
  group_by(iter) |>
  group_split(.keep = FALSE)

# tune mars w/ mlr3mbo
wall("{Sys.time()} -- tuning mars")
dat_earth <- lapply(dat, learn, learner = "earth")
names(dat_earth) <- ids
saveRDS(dat_earth, "dat/interim/mars/earth_mbo.rds")

# estimate performance with nested resampling
wall("{Sys.time()} -- estimating performance via nested resampling")
dat_rr <- lapply(dat, nested_resampling, learner = "earth")
names(dat_rr) <- ids
saveRDS(dat_rr, "dat/interim/mars/earth_nested_resampling.rds")

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
