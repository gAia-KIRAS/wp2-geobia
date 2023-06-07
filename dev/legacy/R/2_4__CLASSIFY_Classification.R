# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.4 CLASSIFICATION: CLASSIFICATION & POST-PROCESSING
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Application of tuned trainings model on completely unseen validation data.
# Afterwards, the classification is post-processed by a neighbor-growing
# procedure.
#
# NOTE: The validation data is already provided in the `data/input/Validation`
#       directory.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 CLASSIFICATION: CLASSIFICATION & POST-PROCESSING
#   2.1 CLASSIFICATION
#   2.2 POST-PROCESSING
#   2.3 VISUALIZE CLASSIFICATIONS
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

# load tuned trainings model
mlr_resultTrain <- readRDS(file = file.path(path_output, "mlr_result_train.rds"))


# load validation data
valid_data <- readRDS(file = file.path(path_validation, "data_valid.rds"))

valid_df <- valid_data$df # data.frame
valid_segment <- valid_data$segment # segmentation of validation area
valid_contiguities <- valid_data$contiguities # list with contiguities
valid_inv <- readRDS(file = file.path(path_validation, "inventory_valid.rds")) # inventory of validation data

# load slp
valid_slp <- raster::raster(x = file.path(path_validation, "slp_valid.sdat"))


# visualize data
raster::plot(valid_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(valid_segment %>% dplyr::filter(Lslide == 1) %>% sf::st_geometry(.), add = TRUE, col = "red")
plot(valid_segment %>% dplyr::filter(Lslide == 2) %>% sf::st_geometry(.), add = TRUE, col = "blue")
plot(valid_inv$sf_inv %>% sf::st_geometry(.), add = TRUE, border = "orange")




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 CLASSIFICATION: CLASSIFICATION & POST-PROCESSING ----------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 CLASSIFICATION  -----------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the tuned trainings model is applied on unseen validation data.

# ... prediction
pred_train2valid <- predict(mlr_resultTrain$model, newdata = valid_df)


# ... performance
perf_train2valid <- mlr::performance(pred = pred_train2valid, measures = list(
  mlr::kappa, mlr::mmce, mlr::bac, mlr::ber, mlr::acc,
  mlr::multiclass.au1p, mlr::multiclass.brier
))


# ... take a look on the object-based accuracies
perf_train2valid
# kappa             mmce              bac              ber              acc  multiclass.au1p multiclass.brier
# 0.5374616        0.1143911        0.7503503        0.2496497        0.8856089        0.9146365        0.1700290




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 POST-PROCESSING -----------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the a post-processing procedure is applied on the classifi-
# cation. The procedure is based on a growing from the scarps with neighbors
# in flow direction. All this is performed on the validation data set!

# ... merge predictions to segmentaton of the validation area and keep only data with prediction information
valid_sf_Lslide_pred <- valid_segment %>%
  merge(
    x = ., by = "ID", all.y = TRUE,
    y = valid_df %>% dplyr::mutate(
      truth = pred_train2valid$data$truth,
      prob_0 = pred_train2valid$data$prob.0,
      prob_1 = pred_train2valid$data$prob.1,
      prob_2 = pred_train2valid$data$prob.2,
      response = pred_train2valid$data$response %>% as.character(.) %>% as.numeric(.)
    ) %>%
      dplyr::select(c("ID", "truth", "prob_0", "prob_1", "prob_2", "response"))
  )

# ... merge predictions to segmentaton of the validation area and keep original data
valid_sf_Lslide_pred_orig <- valid_segment %>%
  merge(
    x = ., by = "ID", all.x = TRUE,
    y = valid_df %>% dplyr::mutate(
      truth = pred_train2valid$data$truth,
      prob_0 = pred_train2valid$data$prob.0,
      prob_1 = pred_train2valid$data$prob.1,
      prob_2 = pred_train2valid$data$prob.2,
      response = pred_train2valid$data$response %>% as.character(.) %>% as.numeric(.)
    ) %>%
      dplyr::select(c("ID", "truth", "prob_0", "prob_1", "prob_2", "response"))
  )





# ... get a "Spatial" copy
valid_sp_Lslide_pred <- as(valid_sf_Lslide_pred, "Spatial")




# ... start growing of scarps
valid_sp_Lslide_scarp <- Lslide::neighborGrowing(
  spdf = subset(valid_sp_Lslide_pred, valid_sp_Lslide_pred@data$response == 1),
  return.gUnaryUnionNeighbors = FALSE, return.input = TRUE
)


# ... get landslide body for corresponding scarps (using growing classes)
valid_df_Lslide_class <- getGrowingClass(
  grownInput = valid_sp_Lslide_scarp,
  col.prob.body = "response",
  nb = valid_contiguities$nb_flow, # flow contiguity
  orig_d = valid_sf_Lslide_pred_orig %>% sf::st_drop_geometry(.),
  thresh = 2,
  out.col1 = "Lslide_cl"
)


# ... add classes with higher or equal probability of 0.8
valid_df_Lslide_AddOn_IDScrp <- valid_sp_Lslide_scarp %>%
  {
    .@data$ID[.@data$response == 1 & .@data$prob_1 >= 0.8]
  } %>%
  setdiff(x = ., y = valid_df_Lslide_class$ID[valid_df_Lslide_class$type == "Scarp_ID"])


valid_df_Lslide_AddOn_IDBody <- valid_sp_Lslide_pred %>%
  {
    .@data$ID[.@data$response == 2 & .@data$prob_2 >= 0.8]
  } %>%
  setdiff(x = ., y = valid_df_Lslide_class$ID[valid_df_Lslide_class$type == "Body_ID"])

# ... create final data.frame
valid_df_Lslide_class_postpros <- valid_df_Lslide_class

if (length(valid_df_Lslide_AddOn_IDScrp) > 0) {
  valid_df_Lslide_class_postpros <- valid_df_Lslide_class_postpros %>%
    rbind(data.frame(Lslide_cl = (max(nrow(.) + 1):(nrow(.) + length(valid_df_Lslide_AddOn_IDScrp))), type = "Scarp_ID", ID = valid_df_Lslide_AddOn_IDScrp))
}

if (length(valid_df_Lslide_AddOn_IDBody) > 0) {
  valid_df_Lslide_class_postpros <- valid_df_Lslide_class_postpros %>%
    rbind(data.frame(Lslide_cl = (max(nrow(.) + 1):(nrow(.) + length(valid_df_Lslide_AddOn_IDBody))), type = "Body_ID", ID = valid_df_Lslide_AddOn_IDBody))
}



# join body and scarps and final growing
# ... joining
valid_sp_Lslide_postpros_merge <- merge(
  x = valid_sf_Lslide_pred,
  y = valid_df_Lslide_class_postpros %>% dplyr::select("ID", "Lslide_cl"),
  by = "ID", all.x = TRUE
) %>%
  as(., "Spatial")

# ... final growing
valid_sp_Lslide_postpros <- Lslide::neighborGrowing(
  spdf = subset(valid_sp_Lslide_postpros_merge, !is.na(valid_sp_Lslide_postpros_merge@data$Lslide_cl)),
  return.gUnaryUnionNeighbors = TRUE,
  return.input = FALSE
)

names(valid_sp_Lslide_postpros) <- "Lslide"

# convert back to sf
valid_sf_Lslide_postpros <- valid_sp_Lslide_postpros %>% sf::st_as_sf(.)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.3 VISUALIZE CLASSIFICATIONS -------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Simple visualization via plot(); use mapview() to interactively assess the
# results.


# visualize data
raster::plot(valid_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(valid_sf_Lslide_pred %>% dplyr::filter(response > 0) %>% sf::st_geometry(.), add = TRUE, col = "red")
plot(valid_sf_Lslide_postpros %>% sf::st_geometry(.), add = TRUE, border = "blue")
plot(valid_inv$sf_inv %>% sf::st_geometry(.), add = TRUE, border = "orange")



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 STORE DATA ------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

valid_Lslide <- list(pred = valid_sf_Lslide_pred, postpros = valid_sf_Lslide_postpros)
saveRDS(object = valid_Lslide, file = file.path(path_output, "valid_Lslide.rds"))
