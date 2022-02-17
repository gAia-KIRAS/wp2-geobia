# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# OPTIMIZATION: REGION GROWING AND MERGING SEGMENTATION
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Optimization procedure for segmentation of candidate landslide scarp area 
# using i.segment of GRASS GIS.
# - Segmentation of slope angle
# - Scale Optimizer using Objective Function
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 REGION GROWING AND MERGING SEGMENTATION





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if("source.R" %in% list.files(file.path(here::here(), "R"))){
  source(file.path(here::here(), "R", "source.R"))
} else {
  stop("Please set your working directory to the project path!")
}

# load raster brick
data_brick <- readRDS(file = file.path(path_input, "brick.rds"))
names(data_brick)
# "dtm"     "open"    "slp"     "cv_max7" "cv_min7" "cv_prf7" "cv_pln7" "RI15"  
# "nH"      "SVF"     "flArLn"  "flSin"   "flCos" "t_Ent51" "t_SD51"

# ... get slope from brick
data_slp <- raster::subset(x = data_brick, subset = 3)

# init GRASS GIS (must be correctly initialized!)
my_search_GRASS7 <- "/home/raphael/grass76/grass-7.6.0/bin.x86_64-pc-linux-gnu/grass76" # this must be adapted!
link2GI::linkGRASS7(x = data_slp, search_path = my_search_GRASS7)

                    
# init SAGA GIS (must be correctly initialized!)
env.rsaga <- RSAGA::rsaga.env()                    
                 


                
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 REGION GROWING AND MERGING SEGMENTATION ----------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# define settings for objective function
optHPT_scaleFactor <- 16 # parameter from the study by "1_Highpass_Filtering_Thresholding.R"
optHPT_filterThreshold <- 5.5 # parameter from the study by "1_Highpass_Filtering_Thresholding.R"
path_save <- tempdir()
sieveThreshold <- 50 # for minimum area of connected pixels
OF_scales <- seq(0.09, 0.07, -0.005) # in the study: c(seq(0.11, 0.001,-0.005))


# Start scale estimation for segmenation of candidate landslide scarp objects using GRASS GIS:
OF_scarps <- Lslide::Objective.Function(Tool = "GRASS", 
                                        Grass.Objective.Function.Method = "High Pass Segmentation", 
                                        Grass.Segmentation.Minsize = 50,
                                        Scale.Statistic.Min.Size = "50",
                                        Scale.Input.Grid = data_slp, 
                                        Scales = OF_scales, 
                                        HiPassFilter.input.segmentation = data_slp, 
                                        HiPassFilter.input.filter = data_slp, 
                                        sieve.thresh = sieveThreshold, 
                                        HiPassFilter.scale.factor = optHPT_scaleFactor, 
                                        HiPassFilter.threshold = optHPT_filterThreshold, 
                                        env = env.rsaga,
                                        Objective.Function.save = TRUE, 
                                        Segments.Grid = file.path(path_save, "optim_OF_scarp.tif"), 
                                        Segments.Poly = file.path(path_save, "optim_OF_scarp.shp"),
                                        Objective.Function.save.path = file.path(path_save, "optim_OF_scarp.csv"))


# ------ Run of Scale Estimation: 1.0424 Minutes

OF_scarps
# Threshold Minsize Intrasegment.Variance Normalized.Intrasegment.Variance  Morans.I Normalized.Morans.I Objective.Function Plateau
# 1     0.090      50              17.70669                        0.0000000 0.4882307           0.9104064          0.9104064 1.24089
# 2     0.085      50              17.15094                        0.5062784 0.4847731           1.0000000          1.5062784 1.24089
# 3     0.080      50              16.94243                        0.6962281 0.4941279           0.7576012          1.4538293 1.24089
# 4     0.075      50              16.87480                        0.7578398 0.5068917           0.4268701          1.1847099 1.24089
# 5     0.070      50              16.60898                        1.0000000 0.5233658           0.0000000          1.0000000 1.24089
# 

# store the result
saveRDS(object = OF_scarps, file = file.path(path_output, "optim_2a_SEGMENT_scarp.rds"))


# Load the results of the study:
