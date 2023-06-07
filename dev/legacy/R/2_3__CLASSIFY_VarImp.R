# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.3 CLASSIFICATION: VARIABLE IMPORTANCE
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Assessment of variable importance using permutation-based importance
# - iterations: 50
# - Cohen's Kappa as measure
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 CLASSIFICATION: VARIABLE IMPORTANCE
# 3 STORE DATA



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if ("source.R" %in% list.files(file.path(here::here(), "R"))) {
  source(file.path(here::here(), "R", "source.R"))
  source(file.path(here::here(), "R", "helper.R"))
} else {
  stop("Please set your working directory to the project path!")
}

# load results of the tuned classifier
mlr_resultTrain <- readRDS(file = file.path(path_output, "mlr_result_train.rds"))



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 CLASSIFICATION: VARIABLE IMPORTANCE -----------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the variable importance for each feature is extracted.


# ... get time of processing
process.time.start <- proc.time()

# ... start variable importance
varImp <- mlr::generateFeatureImportanceData(
  task = mlr_resultTrain$task,
  method = "permutation.importance",
  learner = mlr_resultTrain$tuned_learner,
  measure = list(mlr::kappa),
  nmc = 8, # number of monte-carlo-interations for permutation, in the study: 50
  aggregation = mean
)

process.time.run <- proc.time() - process.time.start
cat(paste0("------ Run of variable importance: ", round(x = process.time.run["elapsed"][[1]] / 60, digits = 4), " Minutes \n"))

# ------ Run of variable importance: 0.932 Minutes



# ... take a look on the result
varImp$res %>%
  t() %>%
  .[order(.), ] %>%
  head(.)
#     slp  t_Ent51_nQ  t_Ent51_nF     open_nQ        open     open_nF
# -0.17415031 -0.14456810 -0.11537279 -0.07598861 -0.07591113 -0.03785836



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 STORE DATA ------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

saveRDS(object = varImp, file = file.path(path_output, "mlr_result_varImp.rds"))
