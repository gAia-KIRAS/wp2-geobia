# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 0 DATA DERIVATION
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Example script to derive data from LiDAR DTM. Only example, NOT EXECUTABLE
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 DERIVE DATA
#   2.1 LAND-SURFACE VARIABLES
#   2.2 TEXTURAL FEATURES






# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if ("source.R" %in% list.files(file.path(here::here(), "R"))) {
  source(file.path(here::here(), "R", "source.R"))
} else {
  stop("Please set your working directory to the project path!")
}

# load raster brick
data_brick <- readRDS(file = file.path(path_input, "brick.rds"))
names(data_brick)
# "dtm"     "open"    "slp"     "cv_max7" "cv_min7" "cv_prf7" "cv_pln7" "RI15"
# "nH"      "SVF"     "flArLn"  "flSin"   "flCos" "t_Ent51" "t_SD51"

# ... get dtm and slope from brick
data_dtm <- raster::subset(x = data_brick, subset = 1)
data_slp <- raster::subset(x = data_brick, subset = 2)

# init GRASS GIS (must be correctly initialized!)
my_search_GRASS7 <- "/home/raphael/grass76/grass-7.6.0/bin.x86_64-pc-linux-gnu/grass76" # this must be adapted!
link2GI::linkGRASS7(x = data_dtm, search_path = my_search_GRASS7)


# init SAGA GIS (must be correctly initialized!)
env.rsaga <- RSAGA::rsaga.env()


# define global settings
path_save <- tempdir()
path_dtm <- file.path(path_save, "dtm.tif")

path_svf_software <- "C:/Software/SkyViewFactor" #  # sky-view factor



# write slope as file
# ... tif
data_dtm %>% raster::writeRaster(x = ., filename = path_dtm, NAflag = -99999, overwrite = TRUE)

## load dtm into GRASS GIS
# print(rgrass7::parseGRASS("r.in.gdal"))
execGRASS("r.in.gdal", flags = c("overwrite", "quiet"), parameters = list(
  input = paste0(tools::file_path_sans_ext(path_dtm), ".tif"), output = "dtm"
))


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 DERIVE DATA -----------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

path_openness <- file.path(path_save, "openness.sgrd")
path_slope <- file.path(path_save, "slp.sgrd")
path_curv_max7 <- file.path(path_save, "curv_max7.sgrd")
path_curv_min7 <- file.path(path_save, "curv_min7.sgrd")
path_curv_prof7 <- file.path(path_save, "curv_prof7.sgrd")
path_curv_plan7 <- file.path(path_save, "curv_plan7.sgrd")
path_dtm_PitRemove <- file.path(path_save, "dtm_fill.tif")
path_flow_Dinf_rad <- file.path(path_save, "flow_Dinf_rad.tif")
path_flow_Dinf_deg <- file.path(path_save, "flow_Dinf_deg.tif")
path_flow_Dinf_sin <- file.path(path_save, "flow_Dinf_sin.tif")
path_flow_Dinf_cos <- file.path(path_save, "flow_Dinf_cos.tif")
path_flow_Dinf_Area <- file.path(path_save, "flow_Dinf_area.tif")
path_flow_Dinf_Area_log <- file.path(path_save, "flow_Dinf_area_log.tif")
path_roughness_i15 <- file.path(path_save, "RI15.tif")
path_normH <- file.path(path_save, "normHeight.sgrd")
path_skyviewfactor <- file.path(path_save, "SVF_R20_D16.tif")
path_textFlowD_Contr51 <- file.path(path_save, "textureFlowDir51_Contr.tif")
path_textFlowD_Entr51 <- file.path(path_save, "textureFlowDir51_Entr.tif")
path_textFlowD_Var51 <- file.path(path_save, "textureFlowDir51_VAR.tif")
path_textFlowD_SD51 <- file.path(path_save, "textureFlowDir51_SD.tif")



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 LAND-SURFACE VARIABLES ----------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# ... Openness as difference between dtm and dtm50
# rsaga.get.usage("statistics_grid", 1, env = env.rsaga)
# MODE: [0] Square
# DISTANCE_WEIGHTING_DW_WEIGHTING: [0] no distance weighting
path_dtm.mean <- file.path(path_save, "dtm_mean.sgrd")
rsaga.geoprocessor(lib = "statistics_grid", env = env.rsaga, module = 1, show.output.on.console = TRUE, param = list(
  GRID = path_dtm, MEAN = path_openness, MODE = "0", RADIUS = 50, BCENTER = "1", DISTANCE_WEIGHTING_DW_WEIGHTING = "0"
))


# formula for calculation
formula.expression <- paste0("a-b")

# rsaga.get.usage("grid_calculus", 1, env = env.rsaga)
rsaga.geoprocessor(lib = "grid_calculus", env = env.rsaga, module = 1, show.output.on.console = FALSE, param = list(
  GRIDS = paste(c(path_dtm, path_openness), collapse = ";"), RESULT = path_openness, FORMULA = formula.expression, FNAME = "1"
))





# ... slope and slope derivatives
## slope
# rsaga.get.usage("ta_morphometry", 0, env = env.rsaga)
# Method 6: [6] 9 parameter 2nd order polynom (Zevenbergen & Thorne 1987)
# Unit is [1] degree
RSAGA::rsaga.geoprocessor(lib = "ta_morphometry", env = env.rsaga, module = 0, show.output.on.console = FALSE, param = list(
  ELEVATION = path_dtm, SLOPE = path_slope, METHOD = "6", UNIT_SLOPE = "1"
))




# ... D-infinity flow
# fill DTM
command <- paste("mpiexec PitRemove -z", path_dtm, "-fel", path_dtm_PitRemove)
system(command, show.output.on.console = TRUE)


## calculate D-Infinity Flow Direction
command <- paste("mpiexec DinfFlowDir -fel", path_dtm_PitRemove, "-ang", path_flow_Dinf_rad)
system(command, show.output.on.console = TRUE)


## calculate D-Infinity Flow Accumulation
command <- paste("mpiexec AreaDinf -ang", path_flow_Dinf_rad, "-sca", path_flow_Dinf_Area, "-nc")
system(command, show.output.on.console = TRUE)

r_flow_Dinf_Area <- raster::raster(path_flow_Dinf_Area)
summary(raster::values(r_flow_Dinf_Area))


r_flow_Dinf_Area.log <- raster::calc(x = r_flow_Dinf_Area, fun = function(x) {
  return(log(x))
})

# write standard deviation in flow direction
raster::writeRaster(x = r_flow_Dinf_Area.log, filename = path_flow_Dinf_Area_log, overwrite = TRUE, NAflag = -99999)


r_flow_Dinf_Area <- raster::raster(path_flow_Dinf_Area)
summary(raster::values(r_flow_Dinf_Area))


r_flow_Dinf_Area_log <- raster::calc(x = r_flow_Dinf_Area, fun = function(x) {
  return(log(x))
})


# write standard deviation in flow direction
raster::writeRaster(x = r_flow_Dinf_Area_log, filename = path_flow_Dinf_Area_log, overwrite = TRUE, NAflag = -99999)


# read raster
r_flow_Dinf <- raster::raster(path_flow_Dinf_rad)

# create cosine and sinus raster for mean value
sin_flow_Dinf <- raster::calc(r_flow_Dinf, fun = function(x) {
  return(sin(x))
})
cos_flow_Dinf <- raster::calc(r_flow_Dinf, fun = function(x) {
  return(cos(x))
})

raster::writeRaster(x = sin_flow_Dinf, filename = path_flow_Dinf_sin, overwrite = TRUE, NAflag = -99999)
raster::writeRaster(x = cos_flow_Dinf, filename = path_flow_Dinf_cos, overwrite = TRUE, NAflag = -99999)


# transformation from radiant to degree AND switch direction
# rotate and write raster: from counter-clockwise to clockwise AND from E = 0 to N = 0 degree
flow_Dinf_Rotated <- raster::calc(r_flow_Dinf, fun = function(x) {
  return((((x * (-180) / pi) + 90) %% 360))
})
raster::writeRaster(x = flow_Dinf_Rotated, filename = path_flow_Dinf_deg, overwrite = TRUE, NAflag = -99999)




# ... Curvature
## Curvature Max by Wood (1996)
# rsaga.get.usage("ta_morphometry", 23, env = env.rsaga)
RSAGA::rsaga.geoprocessor(lib = "ta_morphometry", env = env.rsaga, module = 23, show.output.on.console = FALSE, param = list(
  DEM = path_dtm, MAXIC = path_curv_max7, MINIC = path_curv_min7, PROFC = path_curv_prof7, PLANC = path_curv_plan7, SIZE = 7
))


r_curv_max7 <- raster::raster(paste0(tools::file_path_sans_ext(path_curv_max7), ".sdat"))
r_curv_min7 <- raster::raster(paste0(tools::file_path_sans_ext(path_curv_min7), ".sdat"))

# ... check curvature plan for stange values
r_curv_plan7 <- raster::raster(paste0(tools::file_path_sans_ext(path_curv_plan7), ".sdat"))
r_curv_prof7 <- raster::raster(paste0(tools::file_path_sans_ext(path_curv_prof7), ".sdat"))

summary(raster::values(r_curv_prof7))

r_curv_plan7.val <- raster::values(r_curv_plan7)
summary(r_curv_plan7.val)

## plan curvature
# RSAGA::rsaga.get.usage(lib = "grid_calculus", module = 1, env = env.rsaga)
# METHOD = [6] 9 parameter 2nd order polynom (Zevenbergen & Thorne 1987)
# UNIT_ = [1] degree | [0] radians
RSAGA::rsaga.geoprocessor(lib = "grid_calculus", module = 1, env = env.rsaga, show.output.on.console = TRUE, param = list(
  GRIDS = path_curv_plan7, RESULT = path_curv_plan7, FORMULA = "ifelse(lt(a, (-1)), (-1), ifelse(gt(a, 1), 1, a))", NAME = "curv_plan", FNAME = "1"
))





# ... Surface Roughness
# needs GRASS INITIATION!
GeoMorphTB::roughnessIndex(
  elevation = data_dtm, slope = "", aspect = "", tool = c("RI"), output.path = path_save,
  size = 7, output = path_roughness.i15, return_weighted = FALSE, use.SAGA = TRUE, env = env.rsaga, quiet = FALSE
)


# ... SkyViewFactor
skyViewFactor(
  path.software = path_svf_software, sky_view_factor = c(1, 16, 20, 0, "low"),
  path_save = path_save, quiet = FALSE
)

r_SVF <- r.SVF <- raster::raster(file.path(path_save, "AOI_DGM_01m_SVF_R20_D16.tif"))
r_SVF <- raster::overlay(x = r_SVF, y = data_dtm, fun = function(x, y) {
  ifelse(is.na(y), NA, x)
})

raster::writeRaster(x = r_SVF, filename = path_skyviewfactor, overwrite = TRUE, NAflag = -99999)




# ... NORMALIZED HEIGHT
path_dtm3_tmp <- file.path(path_save, "dtm_res3m.sgrd")


# 1. resample to coarser resolution (3m)
# rsaga.get.usage("grid_tools", 0, env = env.rsaga)
# SCALE_UP: [5] Mean Value (cell area weighted)
rsaga.geoprocessor(lib = "grid_tools", env = env.rsaga, module = 0, show.output.on.console = TRUE, param = list(
  INPUT = path_dtm, OUTPUT = path_dtm3_tmp, SCALE_UP = "5", TARGET_USER_SIZE = 3
))


# 2. calculate normalized height, 𝑤 = 5, 𝑡 = 2, 𝑒 = 2
# rsaga.get.usage("ta_morphometry", 14, env = env.rsaga)
rsaga.geoprocessor(lib = "ta_morphometry", env = env.rsaga, module = 14, show.output.on.console = TRUE, param = list(
  DEM = path_dtm3_tmp, NH = path_normH, W = 5, T = 2, E = 2
))


# 3. resample to coarser resolution (3m)
# rsaga.get.usage("grid_tools", 0, env = env.rsaga)
# SCALE_DOWN: [1] Bilinear Interpolation
rsaga.geoprocessor(lib = "grid_tools", env = env.rsaga, module = 0, show.output.on.console = TRUE, param = list(
  INPUT = path_normH, OUTPUT = path_normH, SCALE_DOWN = "1", TARGET_DEFINITION = "1", TARGET_TEMPLATE = path_dtm
))




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 TEXTURAL FEATURES ---------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # texture
grass.texture.method <- "contrast,var,entr,corr,"
grass.texture.name <- c("_Contr_", "_Var_", "_Entr_", "_Corr_")
grass.texture.save.path <- path_save
texture.output.name <- c("textureFlowDir", "textureFlowDirPer") # same as default


rgrass7::execGRASS("r.in.gdal", flags = c("overwrite", "quiet"), parameters = list(
  input = path_slp, output = "slope"
))

# calculate texture
Lslide::textureFlow(
  grass.texture.flowDir = path_flow_Dinf_deg, grass.texture.input = "slope", grass.texture.method = grass.texture.method, grass.texture.name = grass.texture.name,
  grass.texture.window = 5, grass.texture.distance = 1, grass.texture.save = TRUE, grass.texture.save.path = grass.texture.save.path, show.output.on.console = TRUE, quiet = FALSE
)



# calculate standard deviation from variance
r_textFlowD_Var51 <- raster::raster(path_textFlowD_Var51)
r_textFlowD_SD51 <- raster::calc(r_textFlowD_Var51, fun = function(x) {
  return(sqrt(x))
})
raster::writeRaster(x = r_textFlowD_SD51, filename = path_textFlowD_SD51, overwrite = TRUE, NAflag = -99999)
