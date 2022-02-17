# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# OPTIMIZATION: HIGH-PASS FILTERING AND THRESHOLDING
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Optimization procedure for generation of candidate landslide scarp 
# and body area.
# - High-pass filtering of slope angle
# - Scale Optimizer using F-score
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 HIGH-PASS FILTERING AND THRESHOLDING





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

# load inventory
data_inv <- readRDS(file = file.path(path_input, "inventory.rds"))
names(data_inv)
# "sf_inv"      "sf_inv_prts" "r_inv"       "r_inv_prts"  "r_inv_scrp" 

# ... get inventoried scarps as raster 
data_inv_scarp <- data_inv$r_inv_scrp


# Quick Plot the sope map including the inventoried scarps
raster::plot(x = data_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
raster::plot(x = data_inv_scarp %>% reclassify(x = ., rcl = cbind(-Inf, 0, NA), right = TRUE), col = "red", add = TRUE)


# init SAGA GIS (must be correctly initialized!)
env.rsaga <- RSAGA::rsaga.env()

# define number of cores
number_cores <- 4

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 HIGH-PASS FILTERING AND THRESHOLDING ----------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# define search grid
range_scaleFactor <- c(13:14) # in the study: c(1:30)
range_filterThreshold <- c(4:5) # in the study: seq(from = 1, to = 40, by = 0.5)


# define settings
sieveThreshold <- 50 # for minimum area of connected pixels
timeStamp <-  gsub(pattern = ":|-", replacement = "", Sys.time()) %>% gsub(pattern = "[[:space:]]", replacement = "_", x = .)
file_name <- paste0("run_", timeStamp, ".txt")
path_save <- tempdir()
path_runfile <- file.path(path_save, file_name)


# Start optimizing values for high-pass filtering and threshsolding:
optHPT <- Lslide::optHiPassThresh(x = data_slp, 
                                  inventory = data_inv_scarp, 
                                  range.scale.factor = range_scaleFactor, 
                                  range.threshold = range_filterThreshold,
                                  sieve.thresh = sieveThreshold, 
                                  cores = number_cores, 
                                  quiet = FALSE, 
                                  env.rsaga = env.rsaga,
                                  path.save = path_save, 
                                  path.runfile = path_runfile)

# ... start finding optimal hyper-parameters (parallel) 
# ... ... generation of high-pass filtered images 
# ... ... generation of thesholding images 
# ------ Run of optHiPassThresh:  0.785  Minutes

optHPT
# scale threshold      TN   FN     FP    TP       TPR       TNR       FNR        FPR       acc  rndm_acc   f1score   quality     Kappa
# 1    13         4 1246134 5570 125068 14859 0.7273484 0.9087895 0.2726516 0.09121049 0.9061260 0.8877233 0.1853252 0.1021258 0.1639049
# 2    13         5 1268516 6853 102686 13576 0.6645455 0.9251124 0.3354545 0.07488758 0.9212873 0.9042292 0.1986378 0.1102709 0.1781138
# 3    14         4 1241072 4994 130130 15435 0.7555436 0.9050979 0.2444564 0.09490214 0.9029024 0.8837909 0.1859706 0.1025179 0.1644583
# 4    14         5 1263611 6259 107591 14170 0.6936218 0.9215353 0.3063782 0.07846473 0.9181895 0.9003938 0.1993108 0.1106858 0.1786610



# store the result
saveRDS(object = optHPT, file = file.path(path_output, "optim_1_MASK_HPFT.rds"))


# Load the results of the study:
