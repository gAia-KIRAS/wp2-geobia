# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 ACCURACY ASSESSMENT
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Accuracy assessment on pixel- and object-level.
#  - Cohen's Kappa coefficient
#  - Number of correctly classified inventoried landslides [in %]
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 ACCURACY ASSESSMENT
#   2.1 OBJECT-LEVEL
#   2.2 PIXEL-LEVEL
#   2.3 ACCURACY RESULTS
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

# load inventory
valid_inv <- readRDS(file = file.path(path_validation, "inventory_valid.rds"))

# load classifications
valid_Lslide <- readRDS(file = file.path(path_output, "valid_Lslide.rds"))

# ... predictions
valid_Lslide_pred <- valid_Lslide$pred %>% dplyr::filter(response != 0) 

# ... post-processed
valid_Lslide_postpros <-valid_Lslide$postpros



# init SAGA GIS (must be correctly initialized!)
env.rsaga <- RSAGA::rsaga.env()


# other settings
path_save <- tempdir()
path_inventory <- file.path(path_save, "tmp_inv.tif")


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 ACCURACY ASSESSMENT ---------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 OBJECT-LEVEL  -------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the accuracy of the segmentation is assessed by the number of
# correctly classified inventoried landslides.

# Predictions
# ... get intersection of classification with inventory and its summary
acc_OL_pred <- getIntersectSummary(inventory = valid_inv$sf_inv, Lslide = valid_Lslide_pred)

# ... Correct classified landslides in inventory:  66.66667 % (predicted)
acc_OL_pred_amnt <- length(which(acc_OL_pred$A_GTEQ_50 == 1))/length(unique(acc_OL_pred$Id))*100
cat("Correct classified landslides in inventory: ", acc_OL_pred_amnt, "% (predicted)") 

# Post-Processed
acc_OL_postpros <- getIntersectSummary(inventory = valid_inv$sf_inv, Lslide = valid_Lslide_postpros)

# ... Correct classified landslides in inventory:  66.66667 % (post-processed)
acc_OL_postpros_amnt <- length(which(acc_OL_postpros$A_GTEQ_50 == 1))/length(unique(acc_OL_postpros$Id))*100
cat("Correct classified landslides in inventory: ", acc_OL_postpros_amnt , "% (post-processed)") 




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 PIXEL-LEVEL ---------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the accuracy of the segmentation is assessed on pixel-level
# using the Cohen's Kappa

# write inventory to use it as template
raster::writeRaster(x = valid_inv$r_inv, filename = path_inventory, NAflag = -99999, overwrite = TRUE)


# ... rasterize classifications
# ... ... prediction
r_valid_Lslide_pred <- rsaga.quickRasterization(x.sf = valid_Lslide_pred, 
                                              r.path = path_inventory, 
                                              field = "response", 
                                              out.grid = file.path(path_save , "r_Lslide_postpros.tif"), 
                                              env.rsaga = env.rsaga, 
                                              show.output.on.console = T)

r_valid_Lslide_pred <- r_valid_Lslide_pred %>% 
                       raster::overlay(x = ., y = valid_inv$r_inv, fun = function(x, y) ifelse(is.na(x) & !is.na(y), 0, x))

# ... ... post-processed
r_valid_Lslide_postpros <- rsaga.quickRasterization(x.sf = valid_Lslide_postpros, 
                                         r.path = path_inventory, 
                                         field = "Lslide", 
                                         out.grid = file.path(path_save , "r_Lslide_postpros.tif"), 
                                         env.rsaga = env.rsaga, 
                                         show.output.on.console = T)

r_valid_Lslide_postpros <- r_valid_Lslide_postpros %>% 
                           raster::overlay(x = ., y = valid_inv$r_inv, fun = function(x, y) ifelse(is.na(x) & !is.na(y), 0, x))




# get pixel-level accuracy
acc_PL_pred <- rsaga.calcAccPixelBased(r = r_valid_Lslide_pred, inventory = valid_inv$r_inv, env.rsaga = env.rsaga)
acc_PL_postpros <- rsaga.calcAccPixelBased(r = r_valid_Lslide_postpros, inventory = valid_inv$r_inv, env.rsaga = env.rsaga)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.3 ACCURACY RESULTS ----------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the accuracy results are joined together in one final table

acc_df <- rbind(acc_PL_pred, acc_PL_postpros) %>%
          cbind(data.frame(Type = c("Prediction", "Post-Processed")), .) %>%
          dplyr::mutate(Obj_Lev = c(acc_OL_pred_amnt, acc_OL_postpros_amnt))


# take a look
acc_df 


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 STORE DATA ------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

saveRDS(object = acc_df, file = file.path(path_output, "acc_df.rds"))

