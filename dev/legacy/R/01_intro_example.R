# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# INTRODUCTION INTO EXAMPLE
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Data-sets of example are intoduced.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 PRESENTATION OF DATA
# 3 SOME VISUALISATIONS



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if("source.R" %in% list.files(file.path(here::here(), "R"))){
  source(file.path(here::here(), "R", "source.R"))
  source(file.path(here::here(), "R", "helper.R"))
} else {
  stop("Please set your working directory to the project path!")
}

# load data of example

# Training Area
data_inv <- readRDS(file = file.path(path_input, "inventory.rds")) # ... inventory
data_brick <- readRDS(file = file.path(path_input, "brick.rds")) # ... input variables
data_slp <- raster::raster(x = file.path(path_input, "slp.sdat")) # ... slope-raster (SAGA GIS format)


# Validation Area
valid_inv <- readRDS(file = file.path(path_validation, "inventory_valid.rds")) # ... inventory
valid_data <- readRDS(file = file.path(path_validation, "data_valid.rds")) # ... finalized data
valid_slp <- raster::raster(x = file.path(path_validation, "slp_valid.sdat")) # ... slope-raster (SAGA GIS format)


# Results of example
results_example <- readRDS(file = file.path(path_result, "results_example.rds"))

# Results of study, please see "00_results_study.R"
# results_study <- readRDS(file = file.path(path_result, "results_study.rds"))



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 PRESENTATION OF DATA --------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Training data

# data_inv: contains information of the inventoried landslides; polygon and raster 
# format of entire landslide or splitted parts
names(data_inv) # "sf_inv"      "sf_inv_prts" "r_inv"       "r_inv_prts"  "r_inv_scrp" 

# data_brick: all input variables
names(data_brick) # "dtm"     "open"    "slp"     "cv_max7" "cv_min7" "cv_prf7" "cv_pln7" "RI15"    "nH"      "SVF"     "flArLn"  "flSin"   "flCos"   "t_Ent51" "t_SD51" 

# data_slp: raster of slope 
raster::plot(x = data_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))



# Validation Area
# valid_inv: contains information of the inventoried landslides; polygon and raster 
names(valid_inv) # "sf_inv"      "sf_inv_prts" "r_inv"       "r_inv_prts"  "r_inv_scrp" 


# valid_data: contains information of the data.frame of the validation area, the final segmentation, 
# and contiguities 
names(valid_data) # "df"           "segment"      "contiguities"

# valid_slp: raster of slope 
raster::plot(x = valid_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))




# Results of example
# results_example: contains the basic results of the example (for the case something went wrong)
names(results_example)
# [1] "seg_mask":         mask of training area
# [2] "seg_final"         final segmentation of training area
# [3] "seg_contiguities"  contiguities of traning objects
# [4] "classif_train"     data.frame of training area
# [5] "classif_mlr"       all around the tuned trainings SVM model 
# [6] "classif_varImp"    variable importance of model
# [7] "classif_Lslide"    classification results: predictions and post-processings (validation area)
# [8] "classif_acc"       accuracies of classification (validation area)
# [9] "optim_HPFT"        result of optimization procedure for `mask` step
# [10] "optim_SegmScrp"   result of optimization procedure for `segment` step: Scarps (GRASS GIS)
# [11] "optim_SegmBdy"    result of optimization procedure for `segment` step: Body (SAGA GIS)





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 SOME VISUALISATIONS ---------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# Training area
raster::plot(main = "Training area",
             x = data_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(results_example$seg_final %>% dplyr::filter(LS_CANDI == "B") %>% sf::st_geometry(.), add = T, border = "blue") # ... add candidate landslide bodies
plot(results_example$seg_final %>% dplyr::filter(LS_CANDI == "S") %>% sf::st_geometry(.), add = T, col = "red") # ... add candidate landslide scarps
plot(data_inv$sf_inv %>% sf::st_geometry(.), add = T, border = "yellow") # ... add inventoried landslides


# Validation area
raster::plot(main = "Validation area",
             x = valid_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(results_example$classif_Lslide$pred %>% dplyr::filter(response != 0) %>% sf::st_geometry(.), add = T, col = "blue", border = "blue") # ... add predicted landslides
plot(results_example$classif_Lslide$postpros %>% sf::st_geometry(.), add = T, border = "red") # ... add post-processed landslides
plot(valid_inv$sf_inv %>% sf::st_geometry(.), add = T, border = "yellow") # ... add inventoried landslides


