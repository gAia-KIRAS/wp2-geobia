# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# OPTIMIZATION: SEEDED REGION GROWING SEGMENTATION
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Optimization procedure for segmentation of candidate landslide body
# area using Seeded Region Growing of SAGA GIS.
# - Segmentation of slope angle
# - Scale Optimizer using Objective Function
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 SEEDED REGION GROWING SEGMENTATION





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if ("source.R" %in% list.files(file.path(here::here(), "R"))) {
  source(file.path(here::here(), "R", "source.R"))
} else {
  stop("Please set your working directory to the project path!")
}



# data
path_slp_SAGA <- file.path(path_input, "slp.sgrd") # this file already exists
data_slp <- raster::raster(x = gsub(".sgrd$", ".sdat", path_slp_SAGA))

# file is created during script "1__MASKING_Segmentation.R"
# at step "2.2 PREPARE MASK FOR LANDSLIDE BODY SEGMENTATION"
path_mask <- file.path(path_output, "mask_ScarpBody.tif")


# init GRASS GIS (must be correctly initialized!)
my_search_GRASS7 <- "/home/raphael/grass76/grass-7.6.0/bin.x86_64-pc-linux-gnu/grass76" # this must be adapted!
link2GI::linkGRASS7(x = data_slp, search_path = my_search_GRASS7)


# init SAGA GIS (must be correctly initialized!)
env.rsaga <- RSAGA::rsaga.env()




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 REGION GROWING AND MERGING SEGMENTATION ----------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# define settings for objective function
path_save <- tempdir()
sieveThreshold <- 50 # for minimum area of connected pixels
OF_scales <- seq(4, 3, -0.25) # in the study: seq(8, 1,-0.25)
sieveExpand <- 5
sieveThresh <- 50

var_featureSpace <- data_slp %>%
  raster::values(.) %>%
  var(., na.rm = TRUE) %>%
  round(.) %>%
  as.character(.)


# Start scale estimation for segmenation of candidate landslide body objects using SAGA GIS:
OF_bodies <- Lslide::Objective.Function(
  Tool = "SAGA",
  Seed.Method = "Fast Representativeness",
  Scale.Input.Grid = path_slp_SAGA,
  Input.Grid = path_slp_SAGA,
  Scales = OF_scales,
  Saga.Segmentation.Method = "1",
  Saga.Segmentation.Sig.1 = var_featureSpace,
  Scale.Statistic.Min.Size = "50",
  Saga.Segmentation.Leafsize = 1024,
  Sieving.Flac = TRUE,
  Sieving.Expand = sieveExpand,
  Sieving.Thresh = sieveThresh,
  burn.Boundary.into.Segments = c(TRUE),
  Segmentation.Boundary.Grid = path_mask,
  NoData = TRUE,
  Mask = path_slp_SAGA,
  quiet = FALSE,
  env = env.rsaga,
  show.output.on.console = FALSE,
  Objective.Function.save = TRUE,
  do.storeGrids = TRUE,
  Segments.Grid = file.path(path_save, "optim_OF_body.tif"),
  Segments.Poly = file.path(path_save, "optim_OF_body.shp"),
  Objective.Function.save.path = file.path(path_save, "optim_OF_body.csv")
)

# [1] "Calculate Objective Function"
# [1] "Level of Generalisation|Threshold|Minsize|... : 4"
# [1] "perform fast representativeness for getting seed points"
# [1] "... masking No Data Area in Saga Seeds"
# [1] "SAGA: Perform seeded region growing"
# [1] "Burn Boundary into Segments"
# [1] "perform sieving"
# [1] "vectorising grid classes"
# [1] "clear temp data"
# [1] "------ Run of Segmentation: 0.446883333333244 Minutes ------"
# [1] "Calculate Grid Statistics for Polygons"
# [1] "Extraction for Objective Function Parameter"
# [1] "... Calculation of Intrasegment Variance"
# [1] "... Calculation of Morans'I"
# [1] "------ Run of Extraction for Objective Function Parametern: 0.0242000000000796 Minutes"
# ....
# [1] "------ Run of Scale Estimation: 2.87959999999997 Minutes"



OF_bodies
#     Scale.Parameter Intrasegment.Variance Normalized.Intrasegment.Variance  Morans.I Normalized.Morans.I Objective.Function  Plateau
# 1            4.00              9.566632                        0.0000000 0.3267932           1.0000000          1.0000000 1.011627
# 2            3.75              9.232221                        0.3749035 0.3448342           0.7076809          1.0825845 1.011627
# 3            3.50              9.057874                        0.5703616 0.3684110           0.3256662          0.8960278 1.011627
# 4            3.25              8.779417                        0.8825367 0.3780561           0.1693856          1.0519222 1.011627
# 5            3.00              8.674640                        1.0000000 0.3885100           0.0000000          1.0000000 1.011627


# store the result
saveRDS(object = OF_bodies, file = file.path(path_output, "optim_2b_SEGMENT_bodies.rds"))


# Load the results of the study:
