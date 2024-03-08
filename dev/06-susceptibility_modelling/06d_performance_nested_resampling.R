# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# confusion matrix full
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("data.table")
  library("dplyr")
  library("tidyr")
  library("ggplot2")
  library("glue")
  library("yardstick")
})

rr <- readRDS("dat/interim/random_forest/ranger_nested_resampling.rds")

extract_tbl <- function(x) {
  lapply(x, as.data.table) |>
    bind_rows(.id = "fold") |>
    as_tibble()
}

tmp <- lapply(rr, \(x) x$predictions()) |>
  lapply(extract_tbl) |>
  bind_rows(.id = "iteration") |>
  mutate(fold = as.integer(fold)) |>
  group_by(iteration, fold)


do_summary <- function(x) {
  x |>
    group_by(.metric) |>
    summarize(mean = mean(.estimate), sd = sd(.estimate))
}

lapply(rr, \(x) x$score()) |>
  bind_rows(.id = "iter") |>
  mutate(.metric = "classif.ce") |>
  select(iteration = iter, fold = iteration, .metric, .estimate = classif.ce) |>
  do_summary() |>
  bind_rows(do_summary(bal_accuracy(tmp, truth = truth, response))) |>
  bind_rows(do_summary(f_meas(tmp, truth = truth, response))) |>
  bind_rows(do_summary(kap(tmp, truth = truth, response))) |>
  bind_rows(do_summary(j_index(tmp, truth = truth, response))) |>
  bind_rows(do_summary(mcc(tmp, truth = truth, response))) |> 
  bind_rows(do_summary(brier_class(tmp, truth = truth, prob.TRUE))) |>
  bind_rows(do_summary(pr_auc(tmp, truth = truth, prob.TRUE))) |>
  bind_rows(do_summary(roc_auc(tmp, truth = truth, prob.TRUE)))

cm <- conf_mat(ungroup(tmp), truth = truth, estimate = response)
