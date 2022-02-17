# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. MASKING: HIGH-PASS FILTERING AND THRESHOLDING
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Generation of candidate landslide scarp and body area.
# - High-pass filtering and thresholding of slope angle
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 MASKING AND SEGMENTATION
#   2.1 HIGH-PASS FILTERING, THRESHOLDING AND SEGMENTATION
#   2.2 PREPARE MASK FOR LANDSLIDE BODY SEGMENTATION
#   2.3 SEGMENTATION OF LANDSLIDE BODY AND FINAL MERGING
#   2.4 GET POINTS ON SURFACE FOR LANDSLIDE LABELING
# 3 CLEAN AND WRITE DATA



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


# define global settings
path_save <- tempdir()
path_mask <- file.path(path_output, "mask_ScarpBody.tif")
path_slp <- file.path(path_save , "slp.tif")
path_slp_SAGA <- file.path(path_input , "slp.sgrd") # this file already exists
path_final_segmentation <- file.path(path_output, "segmentFinal.shp")

# write slope as file
# ... tif
data_slp %>% raster::writeRaster(x = ., filename = path_slp, NAflag = -99999, overwrite = TRUE) 



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 MASKING AND SEGMENTATION ----------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 HIGH-PASS FILTERING, THRESHOLDING AND SEGMENTATION -------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the candidate landslide scarp area is generated and segmented.


# define settings
sieveThreshold <- 50 # for minimum area of connected pixels
scaleFactor <- 16 # from study
filterThreshold <- 5.5 # from study
segmentThreshold <- 0.075 # from study
minSize <- 50

# results
path_segmentScarpPoly <- file.path(path_save, "segmentScarp.shp")
path_segmentScarpGrid <- file.path(path_save, "segmentScarp.tif")


# START: Masking of candidate scarp area and segmenting it in one step
Lslide::hiPassSegmentation(input.filter = data_slp, 
                           input.segmentation = data_slp, 
                           scale.factor = scaleFactor, 
                           threshold = filterThreshold, 
                           sieve.thresh = sieveThreshold, 
                           Grass.Segmentation.Threshold = segmentThreshold, 
                           Grass.Segmentation.Minsize = minSize, 
                           Grass.Segmentation.Memory = 4096, 
                           Segments.Poly = path_segmentScarpPoly, 
                           Segments.Grid = path_segmentScarpGrid,
                           env.rsaga = env.rsaga, 
                           show.output.on.console = FALSE, 
                           quiet = FALSE)

# Start High-Pass-Segmentation ...
# ... high-pass filter with scale:  16 
# ... thresholding high-pass filter with threshold:  5.5 
# ... removal of clumbs based on threshold:  50 
# ... ... sieving
# ... shrink and expand
# ------ Run of hiPassThresh:  0.3  Minutes 
#   ... clip input for segmentation based on filter results
# ... GRASS: Start segmentation
# ... GRASS: Vectorising Grid Classes
# ------ Run of contrastFilterSegmentation: 0.371350000000045 Minutes





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 PREPARE MASK FOR LANDSLIDE BODY SEGMENTATION -----------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the mask for the candiate landslide scarp and body area is generated.
# The output can be used in the script "optim__2b__SEGMENT_OF_body.R"

# load segmentaton of scarp grid and plot it
r_segmentScarp <- raster::raster(path_segmentScarpGrid)
r_segmentScarp %>% raster::plot(.)

# check minimum value -> 1
r_segmentScarp %>% raster::cellStats(., stat = 'min', na.rm=TRUE) 

# set NA to 0 for the mask
r_segmentScarp[is.na(r_segmentScarp)] <- 0

# write mask for later use (OF of body and segmentation of body)
r_segmentScarp %>% raster::writeRaster(x = ., filename = path_mask, datatype = "INT4S", overwrite = TRUE)




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.3 SEGMENTATION OF LANDSLIDE BODY AND FINAL MERGING --------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the candidate landslide body area is segmented under consideration of the candidate scarp objects.
# Therefore, the resulted segmentation includes both - candidate body and scarp objects.

# define settings
LevelOfGeneralisation <- 3.25 # from study

# ... variance in feature space for SAGA segmentation (type character): "74"
var_featureSpace <- data_slp %>% raster::values(.) %>% 
                    var(., na.rm = TRUE) %>% round(.) %>% as.character(.)

# results (is basically the final segmentation result!)
path_segmentBodyPoly <- file.path(path_save, "segmentBody.shp")
path_segmentBodyGrid <- file.path(path_save, "segmentBody.sgrd")


Lslide::segmentation(Tool = "SAGA", 
                     Seed.Method = "Fast Representativeness", 
                     Fast.Representativeness.LevelOfGeneralisation = LevelOfGeneralisation,
                     Segmentation.Boundary.Grid = path_mask, # <- here is the scarp-body mask!
                     burn.Boundary.into.Segments = c(TRUE), 
                     Saga.Segmentation.Method = "1", 
                     Saga.Segmentation.Sig.1 = var_featureSpace, 
                     Saga.Segmentation.Leafsize = 1024,
                     Input.Grid = path_slp_SAGA,
                     Sieving.Flac = TRUE, 
                     Sieving.Expand = 5, 
                     Sieving.Thresh = 50,
                     NoData = TRUE, 
                     Mask = path_slp_SAGA, 
                     Segments.Grid = path_segmentBodyGrid, 
                     Segments.Poly = path_segmentBodyPoly, 
                     quiet = FALSE, 
                     show.output.on.console = FALSE, 
                     env = env.rsaga)



# load data and take a look on it
sf_seg <- sf::st_read(dsn = path_segmentBodyPoly)

# ... plot
raster::plot(x = data_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(sf_seg %>% sf::st_geometry(.), add = T, border = "blue")





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.4 GET POINTS ON SURFACE FOR LANDSLIDE LABELING --------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step we assign each object, if it is a candidate scarp or body.
# Since we do not consider minor scarps in our inventoried landslides, we
# must account for those candidate scarp objects inside the landslide body.

# ... get points on surface for candidate scarp segmentation (see 2.1)
ptsOS_seg_scarps <- sf::st_read(dsn = path_segmentScarpPoly) %>% 
                  sf::st_point_on_surface(.) # betten than sf::st_centroid() due to semi-circular polygons!

# ... get index of candiate scarps in final segmentation
seg_indexScarps <- sf::st_intersects(x = ptsOS_seg_scarps, y = sf_seg) %>% unlist(.) %>% unique(.)
 

# ... assign candidate type to segmentation
sf_seg$LS_CANDI <- "B" # for body
sf_seg[seg_indexScarps,]$LS_CANDI <- "S" # for scarp



# ... plot
raster::plot(x = data_slp, col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(sf_seg %>% dplyr::filter(LS_CANDI == "B") %>% sf::st_geometry(.), add = T, border = "blue")
plot(sf_seg %>% dplyr::filter(LS_CANDI == "S") %>% sf::st_geometry(.), add = T, col = "red")


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 CLEAN AND WRITE DATA --------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# clean data
sf_seg <- sf_seg %>% dplyr::mutate(ID = 1:nrow(.)) %>%
                     dplyr::select(c("ID", "LS_CANDI", "geometry"))


# save the final segmentation result
sf_seg %>% sf::st_write(obj = ., dsn = path_final_segmentation, delete_layer = TRUE)
