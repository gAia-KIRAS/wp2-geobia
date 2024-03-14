library("sf")
library("ggplot2")
library("biscale")

# xmin <- 430000
# xmax <- 435500
# ymin <- 318500
# ymax <- 322500
# aoi <- st_sfc(st_polygon(list(cbind(c(xmin, xmax, xmax, xmin, xmin), c(ymin, ymin, ymax, ymax, ymin)))), crs = 3416)
# res <- qs::qread("dat/processed/prediction/random_forest_prediction_mean_sd_sf.qs", nthreads = 16L) |>
#   st_intersection(aoi)
# saveRDS(res, "dat/processed/prediction/biscale_test_aoi.rds")

res <- readRDS("dat/processed/prediction/biscale_test_aoi.rds")
