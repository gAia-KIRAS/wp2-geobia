# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 CLASSIFICATION: TRAININGS MODEL - SUPPORT VECTOR MACHINE
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Creation of tuned trainings model with support vector machine (SVM) as 
# classifier:
# - 5:1:1 non-landslide to landslide ratio
# - tuning cost and gamma
# - random search
# - Cohen's Kappa as measure
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 CLASSIFICATION: TRAININGS MODEL - SUPPORT VECTOR MACHINE
#   2.1 CREATE FINAL TRAINING DATA
#   2.2 INIT MLR MODEL FRAMEWORK
#   2.3 SPATIAL TUNING OF TRAININGS MODEL 
# 3 STORE DATA



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if("source.R" %in% list.files(file.path(here::here(), "R"))){
  source(file.path(here::here(), "R", "source.R"))
  source(file.path(here::here(), "R", "helper.R"))
} else {
  stop("Please set your working directory to the project path!")
}

# load trainings data
df_train <- readRDS(file = file.path(path_output, "df_train.rds")) %>%
              dplyr::mutate(Lslide = Lslide %>% as.factor(.))



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 CLASSIFICATION: TRAININGS MODEL - SUPPORT VECTOR MACHINE----------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 CREATE FINAL TRAINING DATA  -----------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the final trainings data is created.

# ... check candidate to labeld landslide and non-landslide objects
table(df_train$Lslide, df_train$LS_CANDI)
#     B    S
# 0 1081  474
# 1    0  245
# 2  335    0


# # # #
# ... we can see that a ratio of landslide to non-landslide object is not possible.
#     Therefore, we take the entire data.frame. However, the following code demon-
#     strates how the data.frame was resample with 5:1:1 ratio in the study:
df_train_fin <- df_train %>% 
                finalDF(df = ., do.sample = TRUE, ratio = 1.5, # in the study ratio: 5
                        col = "Lslide", v.T = c(1, 2), 
                        col.fit = "LS_CANDI", v.fit = c("S", "B")) 

df_train_fin_xy <- df_train_fin %>% dplyr::select(c("X", "Y"))
#
# # # 



# ... data for training model
df_train_mod <- df_train %>% dplyr::select(-c("Scarp", "Body", "X", "Y", "ID", "LS_CANDI", "MnDir",
                                              "dtm", "flSin", "flCos", "P", "P_sqrt_A", "Flow", "FlowInv",
                                              "D_A", "D_sqrt_A", "A_cHull", "P_cHull", "A"))

df_train_mod_xy <- df_train %>% dplyr::select(c("X", "Y"))


# ... take a look on the data
summary(df_train_mod)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 INIT MLR MODEL FRAMEWORK --------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step, the mlr-modeling framework is initiated

# ... create tuning parameter
mlr_svm_ps <- ParamHelpers::makeParamSet(
  ParamHelpers::makeNumericParam("cost", lower = -12, upper = 15, trafo = function(x) 2^x),
  ParamHelpers::makeNumericParam("gamma", lower = -15, upper = 6, trafo = function(x) 2^x)
)


# ... create random search grid
mlr_ctrl_tune <- mlr::makeTuneControlRandom(maxit = 25) # in the study: 250


# ... inner resampling loop
mlr_inner <- mlr::makeResampleDesc("SpCV", iters = 5, predict = "both")


## create tasks
# ... train
mlr_task_train <- mlr::makeClassifTask(id = "TRAIN", data = df_train_mod, 
                                   target = "Lslide", coordinates = df_train_mod_xy)


# ... create learner or classifier - Support Vector Machine from the e1071-package
mlr_lrn_svm <- mlr::makeLearner("classif.svm", predict.type = "prob")


# ... tuning settings:
mlr_mode <- "multicore" # mode of processing - here: parallel on multicores
mlr_measures <- list(mlr::kappa) # measure for evaluating the model fit - here: Cohen's Kappa
mlr_n_cpus <- 10 # number of CPUs
mlr_level <- "mlr.tuneParams" # level in which parallelisation takes place

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.3 SPATIAL TUNING OF TRAININGS MODEL -----------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# ... get start time
process.time.start <- proc.time()


# ... tune learner
mlr::configureMlr(on.learner.error = "warn", on.error.dump = TRUE)

# ... ... parallelize tuning
parallelMap::parallelStart(mode = "multicore", level = mlr_level, cpus = mlr_n_cpus, mc.set.seed = TRUE)
set.seed(888)
  
mlr_res_tuning <- mlr::tuneParams(learner = mlr_lrn_svm,
                                  task = mlr_task_train, 
                                  control =  mlr_ctrl_tune, 
                                  show.info = TRUE,  
                                  par.set = mlr_svm_ps, 
                                  resampling = mlr_inner, 
                                  measures = mlr_measures)
  
parallelMap::parallelStop()

process.time.run <- proc.time() - process.time.start
cat(paste0("------ Run of tuning: " , round(x = process.time.run["elapsed"][[1]]/60, digits = 4), " Minutes \n"))

# [Tune] Started tuning learner classif.svm for parameter set:
# Type len Def    Constr Req Tunable Trafo
# cost  numeric   -   - -12 to 15   -    TRUE     Y
# gamma numeric   -   -  -15 to 6   -    TRUE     Y
# With control class: TuneControlRandom
# Imputation value: 1
# Mapping in parallel: mode = multicore; level = mlr.tuneParams; cpus = 10; elements = 25.
# [Tune] Result: cost=7.98; gamma=0.00244 : kappa.test.mean=0.4781377
# Stopped parallelization. All cleaned up.
# ------ Run of tuning: 0.8485 Minutes 


# ... create tuned learner
mlr_lrn_svm_tuned <- mlr::setHyperPars(mlr_lrn_svm, par.vals = mlr_res_tuning$x)


# ... train the learner
mlr_mod_SVM <- mlr::train(learner = mlr_lrn_svm_tuned, task = mlr_task_train)


# ... create result
mlr_resultTrain <- list(task = mlr_task_train, tune_result = mlr_res_tuning, 
                        tuned_learner = mlr_lrn_svm_tuned, model = mlr_mod_SVM)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 STORE DATA ------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

saveRDS(object = mlr_resultTrain, 
        file = file.path(path_output, "mlr_result_train.rds"))
