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

ncores <- 29L

source("wp2-geobia/dev/utils.R")

ids <- glue("iteration-{sprintf('%02d', 1:10)}")

wall("{Sys.time()} -- reading data")
dat <- qread("wp2-geobia/dat/processed/gaia_noe_balanced_iters.qs", nthreads = ncores) 
dat %>%
  select(
    # -elevation, 
    -maximum_height, 
    # -wei,
    # -roughness, 
    # -tri, 
    -svf,
    -pto, -nto, -curv_max, -curv_min, -dah,
    -flow_path_length, -flow_width, -sca,
    -api_k7, -api_k30, -rx1day, -rx5day, -sdii,
    # -forest_cover,
    -road_dist,
    #  -sw_hazard_cat, -sw_max_depth, -sw_max_speed,
    # -esa
  ) #%>%
  # mutate(slide = as.factor(slide)) %>%
  # group_by(iter) %>%
  # drop_na() %>%
  # group_split(.keep = FALSE)

dat <- dat %>%
  mutate(slide = as.factor(slide)) %>%
  group_by(iter) %>%
  drop_na() %>%
  group_split(.keep = FALSE)

qsave(dat, "wp2-geobia/dat/processed/gaia_noe_balanced_iters_forML.qs", nthreads = ncores)

dat <- qread("wp2-geobia/dat/processed/gaia_noe_balanced_iters_forML.qs", nthreads = ncores) 

# tune random forest w/ mlr3mbo
wall("{Sys.time()} -- tuning rf")
dat_rf <- lapply(dat, learn, learner = "randomforest")
names(dat_rf) <- ids
saveRDS(dat_rf, "wp2-geobia/dat/interim/random_forest/ranger_mbo.rds")

# SKIPPING for now
# estimate performance with nested resampling
wall("{Sys.time()} -- estimating performance via nested resampling")
dat_rr <- lapply(dat, nested_resampling, learner = "randomforest")
names(dat_rr) <- ids
saveRDS(dat_rr, "wp2-geobia/dat/interim/random_forest/ranger_nested_resampling.rds")

# get metrics
wall("{Sys.time()} -- obtaining metrics")
met <- lapply(dat_rr, get_score) %>%
  bind_rows(.id = "key")

# summarize across all single folds
met %>%
  summarize(
    min_score = min(classif.ce),
    mean_score = mean(classif.ce),
    max_score = max(classif.ce)
  )

# aggregate all folds per iteration and summarize across all iterations
met %>%
  group_by(iteration) %>%
  summarize(classif.ce = mean(classif.ce)) %>%
  ungroup() %>%
  summarize(
    min_score = min(classif.ce),
    mean_score = mean(classif.ce),
    max_score = max(classif.ce)
  )

lapply(dat_rr, get_inner_tuning) %>%
  bind_rows(.id = "key")
