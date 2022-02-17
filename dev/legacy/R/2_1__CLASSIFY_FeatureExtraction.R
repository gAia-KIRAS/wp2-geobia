# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 CLASSIFICATION: FEATURE EXTRACTION
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Feature extraction of the segmentation result. Object statistics:
# - Land-surface variables
# - Textural features
# - Queen's and flow contiguity
# - Shape metrics
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 CLASSIFICATION: FEATURE EXTRACTION
#   2.1 LAND-SURFACE VARIABLES AND TEXTURAL FEATURES
#   2.2 SHAPE METRICS
#   2.3 QUEEN'S AND FLOW CONTIGUITY
#   2.4 CLEAN DATA AND ADD COORDINATES
#   2.5 ADD RESPONSE DATA (LABELLING PROCEDURE)
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

# load raster brick
data_brick <- readRDS(file = file.path(path_input, "brick.rds"))
names(data_brick)
# "dtm"     "open"    "slp"     "cv_max7" "cv_min7" "cv_prf7" "cv_pln7" "RI15"  
# "nH"      "SVF"     "flArLn"  "flSin"   "flCos" "t_Ent51" "t_SD51"

# ... get slope from brick
data_slp <- raster::subset(x = data_brick, subset = 3)


# define global settings
path_save <- tempdir()
path_final_segmentation <- file.path(path_output, "segmentFinal.shp")
path_final_segmentation_tmp_LSTF <- file.path(path_save , "tmp_LSTF_segmentFinal.shp")
path_final_segmentation_tmp_SM <- file.path(path_save , "tmp_SM_segmentFinal.shp")
cores_number <- 4
label_threshold <- 60

# load segmentation
sf_seg <- sf::st_read(dsn = path_final_segmentation)

# load inventoried landslides
inv <- readRDS(file = file.path(path_input, "inventory.rds"))
inv_parts <- inv$sf_inv_prts
  


# init GRASS GIS (must be correctly initialized!)
my_search_GRASS7 <- "/home/raphael/grass76/grass-7.6.0/bin.x86_64-pc-linux-gnu/grass76" # this must be adapted!
link2GI::linkGRASS7(x = data_slp, search_path = my_search_GRASS7)


# init SAGA GIS (must be correctly initialized!)
env.rsaga <- RSAGA::rsaga.env()




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 CLASSIFICATION: FEATURE EXTRACTION ------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.1 LAND-SURFACE VARIABLES AND TEXTURAL FEATURES  ------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step objects statistics are extracted for land-surface variables 
# and textural features. Since raster::extract() on large data-sets can be 
# quite slow, we use SAGA GIS for this operation. However, at first, the 
# bricked data must be written to the hard disk.


# ... write data
path_grids <- lapply(X = 1:raster::nlayers(data_brick), FUN = function(x, data_brick, path_save){

    x.name <- names(data_brick)[x]
  x.filename <- file.path(path_save, paste0(x.name, ".tif"))
  cat(x, " from ", raster::nlayers(data_brick), ": ", x.name, "\n")
  
  x.tmp <- raster::subset(x = data_brick, subset = x)
  raster::writeRaster(x = x.tmp, filename = x.filename, NAflag = -99999, overwrite = TRUE)
  
  return(x.filename)
}, data_brick = data_brick, path_save = path_save)
  
  
# ... extract object statistics using SAGA GIS
# the result is stored to a temporary shape file
# rsaga.get.usage(lib="shapes_grid", module = 2, env = env.rsaga)
rsaga.geoprocessor(lib="shapes_grid", module = 2, env = env.rsaga, show.output.on.console = TRUE, param = list(
  GRIDS = paste0(path_grids, collapse = ";"), POLYGONS = path_final_segmentation, RESULT = path_final_segmentation_tmp_LSTF,
   METHOD = "0", NAMING = "1", COUNT = "0", MIN = "0", MAX = "0", RANGE = "0", SUM = "0", MEAN = "1", VAR = "0", STDDEV = "0", QUANTILE = 0))



# ... now we load the shapefile and rename it properly
sf_segStats <- sf::st_read(dsn = path_final_segmentation_tmp_LSTF)

sf_segStats <- sf_segStats %>% dplyr::rename(.data = ., dtm = dtm..MEAN.,
                               open = open..MEAN.,
                               slp = slp..MEAN.,
                               cv_max7 = cv_max7..ME,
                               cv_min7 = cv_min7..ME,
                               cv_prf7 = cv_prf7..ME,
                               cv_pln7 = cv_pln7..ME,
                               RI15 = RI15..MEAN.,
                               nH = nH..MEAN.,
                               SVF = SVF..MEAN.,
                               flArLn = flArLn..MEA,
                               flSin = flSin..MEAN, 
                               flCos = flCos..MEAN,
                               t_Ent51 = t_Ent51..ME, 
                               t_SD51 = t_SD51..MEA)

names(sf_segStats)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.2 SHAPE METRICS  ------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step the shape metrics of the objects are calculated.

# calculate shape indices using SAGA GIS
# we use for the calculation the temporary shapefile from step 2.1
rsaga.geoprocessor(lib="shapes_polygons", module = 7, env = env.rsaga, show.output.on.console = TRUE, param = list(
  SHAPES = path_final_segmentation, INDEX = path_final_segmentation_tmp_SM))


# ... now we load the shapefile, select relevant infomration and bind that to result of step 2.1
sf_segStatsSM <- sf::st_read(dsn = path_final_segmentation_tmp_SM)

# ... selection (Note: Different SAGA GIS versions may have different output column names, so it is possible that names must be adapted!!!)
sf_segStatsSM <- sf_segStatsSM %>% dplyr::select(names(sf_segStatsSM)[names(sf_segStatsSM) %in% 
                                                                        c("P", "P.A", "P.sqrt.A", "P.sqrt.A.", "Dmax", "Dmax.A", "Dmax.sqrt.A", "Shape.Index", 
                                                                          "Perimeter", "Max.Distanc", "D.A", "D.sqrt.A.", "geometry")])

# ... rename
sf_segStatsSM <- sf_segStatsSM %>% dplyr::rename(# P = Perimeter, # must be outcommented depeending on the SAGA GIS version
                                                 P_A = P.A,
                                                 P_sqrt_A = P.sqrt.A., 
                                                 Mx_Dist = Dmax, # or Max.Distanc, 
                                                 D_A = Dmax.A, # or D.A,
                                                 D_sqrt_A = Dmax.sqrt.A, # D.sqrt.A.,
                                                 Sh_Ind = Shape.Index)
                                                 
# ... calculate compactness and convexity
sf_segStatsSM_cHull <- sf_segStatsSM %>% sf::st_convex_hull(x = .)

sf_segStatsSM <- sf_segStatsSM %>% dplyr::mutate(A_cHull = sf_segStatsSM_cHull %>% sf::st_area(x = .) %>% as.numeric(.),
                                                 P_cHull = sf_segStatsSM_cHull %>% VLSM::st_perimeter(x = .),
                                                 A = sf::st_area(.) %>% as.numeric(.),
                                                 Conv = A/A_cHull,
                                                 Comp = A/(P_cHull^2) *4 * pi)

# ... add data to sf_segStats
cat("check: is number of rows identical: ", identical(nrow(sf_segStatsSM), nrow(sf_segStats)), "\n")
sf_segStats <- sf_segStats %>% dplyr::bind_cols(., sf_segStatsSM %>% sf::st_drop_geometry(.))




# ... calculation of mean flow direction and inverse
sf_segStats <- sf_segStats %>% dplyr::mutate(Flow  = ((atan2(flSin, flCos) * (-180)/pi) + 90) %% 360,
                                             FlowInv = (Flow   - 180 + 360) %% 360)


# ... calculation main direction/object orientation and length-to-width ratio
df_moreMetrics <- getMoreMetrics(seg.sp = sf_segStats %>% as(., "Spatial"), flowDir = sf_segStats$Flow, cores = cores_number)
# ------ Run of MainDirection: 0.0399 Minutes 
# ------ Run of LengthWidthRatio: 0.0278 Minutes

# ... merge data back
sf_segStats <- sf_segStats %>% merge(x = ., y = df_moreMetrics, by = "ID", all.x = TRUE)





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.3 QUEEN'S AND FLOW CONTIGUITY------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step object statistics are calculated for flow and Queen's contiguity


# ... derivation of contiguities
list_contiguities <- extractNeighborhoods(seg.sf = sf_segStats, seg.sp = sf_segStats %>% as(., "Spatial"), cores = cores_number)
# ------ Run of getBoundingBox: 0.0104 Minutes  
# ------ Run of getBoundingBox: 0.0327 Minutes 
# Point on surface...
# Start loop...
# ------ Run of ClassNeighborFunction:  0.0208  Minutes 


names(list_contiguities)
# [1] "nb_queen" "nb_flow" 

# store contiguities for final growing step
saveRDS(object = list_contiguities, file = file.path(path_output, "list_contiguities.rds"))


# ... define the feature column names on which statistics of contiguities are calculated: 
# here on land-surface variables and textural features
# names(sf_segStats)
feature_col_names <-  c("slp", "open", "cv_max7", "cv_min7", "cv_prf7", "cv_pln7", 
                        "RI15", "nH", "SVF", "flArLn", "t_Ent51", "t_SD51")


# ... calculation of object statistics under consideration of contiguities
contiguity_Queen <- nbStat(nb = list_contiguities$nb_queen, col.names = feature_col_names, col.area = "A", in.seg = sf_segStats, suffix = "_nQ")
contiguity_Flow <- nbStat(nb = list_contiguities$nb_flow, col.names = feature_col_names, col.area = "A", in.seg = sf_segStats, suffix = "_nF")


# ... merge data 
sf_segStats <- sf_segStats %>% merge(x = ., y = contiguity_Queen, by = "ID", all.x = TRUE) %>%
                               merge(x = ., y = contiguity_Flow, by = "ID", all.x = TRUE)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.4 CLEAN DATA AND ADD COORDINATES --------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step, NA values of the flow contiguity are overwritten by the Queen's 
# contiguity. In addition, coordinates are added to the segmentation.

# ... clean data
sf_segStatsFin <- sf_segStats %>% finCleaning(in.seg = .)

# ... get coordinates using sf::st_point_on_surface() to ensure that on every point is INSIDE of the corresponding polygon
sf_segStatsFin_PoS <- sf_segStats %>% sf::st_point_on_surface(x = .) 
coords_segStats <- sf_segStatsFin_PoS %>% sf::st_coordinates(.)

sf_segStatsFin <- sf_segStatsFin %>% dplyr::mutate(X = coords_segStats[, 1],
                                                   Y = coords_segStats[, 2])





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2.5 ADD RESPONSE DATA (LABELLING PROCEDURE) -----------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# In this step, an objective and automatic labelling procedure is applied
# to mark object as landslide or non-landslide object.
#
# An object is labelled as landslide object if one of the following conditions
# are met:
#   1. a point on the object's surface is located inside an inventoried landslide
#   2. 60% of the area of an object is located inside an inventoried landslide
#
# NOTE: Due to missing minor scarps in the landslide body. Candidate scarps 
#       in the landslide body must be considered as candidate scarp objects!


# ... CONDITION 1: intersect segmentation with inventoried landslides
intersPoly2Inv <- sf::st_intersection(x = sf_segStatsFin, y = inv_parts)


# ... .... create data.table of threshold information
df_Poly2Inv <- intersPoly2Inv %>% 
  dplyr::mutate(.data = ., A_m_sq_inter = sf::st_area(.) %>% as.numeric(.)) %>% # calculate area of intersection
  sf::st_set_geometry(x = ., value = NULL) %>% # summarize by intersecting scarp area and total intersected area
  data.table::as.data.table(.)

df_Poly2Inv_summ <- df_Poly2Inv %>% 
                            .[, list(A = sum(A_m_sq_inter), A_orig = mean(A_m_sq)), by = list(ID, LS_CANDI, LS_PART)] %>%
                            dplyr::mutate(.data = ., A_Q = A/A_orig * 100,  
                                          TRUE_Scrp = ifelse(LS_CANDI == "S" &  A_Q >= label_threshold, 1, 0),
                                          TRUE_Bdy = ifelse(LS_CANDI == "B" & LS_PART == "B" &  A_Q >= label_threshold, 1, 0))

# df_Inv_summ <- df_Poly2Inv %>% 
#   .[, list(A_m_sq_inter = sum(A_m_sq_inter), Count = length(unique(ID))), by = list(Id,  LS_PART, A_m_sq, LS_CANDI)] %>%
#   dplyr::mutate(A_ratio = A_m_sq_inter*100/A_m_sq)



# ... CONDITION 2: intersect points on the object's surface with inventoried landslide
intersPts2Inv <- sf::st_intersection(x = sf_segStatsFin_PoS, y = inv_parts)

df_Pts2Inv <- intersPts2Inv %>% 
                        dplyr::mutate(.data = ., 
                                      TRUE_Scrp = ifelse(LS_CANDI == "S", 1, 0),
                                      TRUE_Bdy = ifelse(LS_CANDI == "B" & LS_PART == "B", 1, 0)) %>%
                        sf::st_set_geometry(x = ., value = NULL)



# ... get TRUE object IDs
ID.TRUE.Scrp <- c(df_Pts2Inv %>% dplyr::filter(TRUE_Scrp == 1) %>% dplyr::select(ID),
                  df_Poly2Inv_summ %>% dplyr::filter(TRUE_Scrp == 1) %>% dplyr::select(ID)) %>% 
                  unlist(.) %>% unique(.)

ID.TRUE.Bdy <- c(df_Pts2Inv %>% dplyr::filter(TRUE_Bdy == 1) %>% dplyr::select(ID),
                 df_Poly2Inv_summ %>% dplyr::filter(TRUE_Bdy == 1) %>% dplyr::select(ID)) %>%
                 unlist(.) %>% unique(.)


# ... label objects
sf_segStatsFin$Scarp <- 0
sf_segStatsFin[which(sf_segStatsFin$ID %in% ID.TRUE.Scrp),]$Scarp <- 1

sf_segStatsFin$Body <- 0
sf_segStatsFin[which(sf_segStatsFin$ID %in% ID.TRUE.Bdy),]$Body <- 1


sf_segStatsFin$Lslide <- 0
sf_segStatsFin[which(sf_segStatsFin$ID %in% ID.TRUE.Bdy),]$Lslide <- 2
sf_segStatsFin[which(sf_segStatsFin$ID %in% ID.TRUE.Scrp),]$Lslide <- 1



# plot data
raster::plot(raster::subset(x = data_brick, subset = 3), col = rev(gray.colors(10, start = 0, end = 0.9, alpha = 0.9)))
plot(sf_segStatsFin %>% dplyr::filter(Lslide == 1) %>% sf::st_geometry(.), add = TRUE, col = "red")
plot(sf_segStatsFin %>% dplyr::filter(Lslide == 2) %>% sf::st_geometry(.), add = TRUE, col = "blue")




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 STORE DATA ------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

saveRDS(object = sf_segStatsFin %>% sf::st_drop_geometry(.), 
        file = file.path(path_output, "df_valid.rds"))
