# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# confusion matrix full
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("dplyr")
  library("tidyr")
  library("ggplot2")
  library("glue")
  library("qs")
  library("yardstick")
})

print(glue::glue("{Sys.time()} -- loading data"))

ncores <- 16L

mod_type <- "random_forest"
# mod_type <- "earth"
# mod_type <- "earth_esa"

res <- qread(glue("dat/processed/prediction/mod-vs-obs/{mod_type}.qs"), nthreads = ncores) |>
  select(obs = slide, susc = mean_susc) |>
  mutate(mod = if_else(susc >= 0.5, TRUE, FALSE)) |>
  mutate(across(where(is.logical), as.factor))

bal_accuracy(res, truth = obs, mod)
f_meas(res, truth = obs, mod)
kap(res, truth = obs, mod)

brier_class(res, truth = obs, susc)
pr_auc(res, truth = obs, susc)
roc_auc(res, truth = obs, susc)

cm <- conf_mat(res, truth = obs, estimate = mod)

TP <- cm$table[2, 2]
TN <- cm$table[1, 1]
FP <- cm$table[2, 1]
FN <- cm$table[1, 2]
