print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("readr")
  library("dplyr")
  library("sf")
  library("qs")
  library("glue")
  library("tictoc")
})

source("wp2-geobia/dev/utils.R")

ncores <- 28L

# x = read_sf("Rutschungen_gesamt.shp") # Masterarbeit
# y = read_sf("Rutschungsflaechen.shp") # KAGIS
# max(st_area(x))                           # 2794285 [m^2]
# quantile(st_area(x), 0.99)                #  426832 [m^2]
# quantile(st_area(y), 0.99)                #   35301 [m^2]
# max(st_area(y))                           #  101170 [m^2]
# quantile(c(st_area(x), st_area(y)), 0.99) #  288733 [m^2]
# sqrt(288733 / pi) = 303

wall("{Sys.time()} -- reading inventory")
inv <- read_sf("wp2-geobia/dat/interim/noe-inventory/noe/ALS_Massenbewegungskartierung_MONOE.shp") %>%
  mutate(slide = TRUE) %>%
  select(slide, geometry) %>%
  st_transform(3416) %>%
  st_buffer(units::as_units(300, "m")) %>%
  st_union()
st_write(inv, "wp2-geobia/dat/interim/noe-inventory/inv_buffered.gpkg", append = FALSE)

# inv <- read_sf("wp2-geobia/dat/interim/noe-inventory/inv_buffered.gpkg")

wall("{Sys.time()} -- reading AOI")
aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea.shp")  %>% 
  st_transform(3416)

# IGNORE for NOE
# wall("{Sys.time()} -- reading lakes")
# lakes <- read_sf("dat/raw/water_bodies/OWK_SG.gpkg") %>%
#  st_transform(3416) %>%
#  select(See) %>%
#  st_intersection(aoi)
# lakes %>%
#  mutate(area = st_area(geom)) %>%
#  st_drop_geometry()

# Ignored for now
wall("{Sys.time()} -- reading lithology")
litho_class <- read_tsv("wp2-geobia/doc/data_description/reclass_geology.tsv") %>%
  select(-lithologie)

litho <- read_sf("wp2-geobia/dat/raw/geology/200k/Geologie_Kaernten_200.000.gpkg") %>%
  st_transform(3416) %>%
  select(leg_litho, geom) %>%
  left_join(litho_class, by = "leg_litho") %>%
  filter(class == 0) %>%
  select(-class)
litho %>%
  mutate(area = st_area(geom)) %>%
  group_by(leg_litho) %>%
  summarize(area = sum(area)) %>%
  st_drop_geometry()
read_csv("doc/data_description/lut_lithology_200k_raw.csv") %>%
  filter(leg_litho %in% c(2, 3, 15, 104, 930, 931))

wall("{Sys.time()} -- cutting holes")
absence_area <- st_difference(aoi, inv) %>%
  st_difference(st_union(litho)) %>%
  mutate(neg_sample = TRUE)

# # without changed geological classes
# lithology <- read_sf("wp2-geobia/dat/raw/lithology/Lithologie_II.shp")  %>% 
#   st_transform(3416)

# lithology_mod <- lithology %>%
#   select(Legend_fin, geometry) %>%
#   mutate(area = st_area(geometry)) %>%
#   group_by(Legend_fin) %>%
#   summarize(area = sum(area)) 

# #st_write(lithology_mod, "wp2-geobia/dat/interim/aoi/lithology_mod.gpkg")

# wall("{Sys.time()} -- cutting holes")
# absence_area_mod <- st_difference(aoi, inv) %>%
#   mutate(neg_sample = TRUE)

# absence_area_test <- absence_area_mod %>%
#   st_difference(st_union(lithology_mod)) %>%
#   mutate(neg_sample = TRUE)

# wall("{Sys.time()} -- saving absence area")
# if (!file.exists("wp2-geobia/dat/interim/aoi/absence_area.gpkg")) {
#   st_write(absence_area_mod, "wp2-geobia/dat/interim/aoi/absence_area.gpkg")
# }

# excluding class 0 (Maske)
litho <- read_sf("wp2-geobia/dat/raw/lithology/Lithologie_II_classes.shp")  %>% 
  st_transform(3416)
  # litho = lithology_reclass

litho_absence <- litho %>%
  select(class, class.name, geometry) %>%
  filter(class == 0) %>%
  select(-class)

litho_absence <- litho_absence %>% mutate(area = st_area(geometry)) %>%
  group_by(class.name) %>%
  summarize(area = sum(area)) %>%
  st_drop_geometry()
  
wall("{Sys.time()} -- cutting holes")
absence_area <- st_difference(aoi, inv) %>%
  st_difference(litho_absence) %>%
  mutate(neg_sample = TRUE)

# absence_area_bcp <- absence_area
absence_area <- st_union(absence_area)

# p <- ggplot() +
#   geom_sf(data = result) +
#   theme_minimal()
# ggsave(p, filename = "wp2-geobia/plt/absence_area_check.png")

# wall("{Sys.time()} -- saving absence area")
# if (!file.exists("wp2-geobia/dat/interim/aoi/absence_area.gpkg")) {
#   st_write(absence_area, "wp2-geobia/dat/interim/aoi/absence_area.gpkg")
# }

st_write(absence_area, "wp2-geobia/dat/interim/aoi/absence_area_diss.gpkg")


wall("{Sys.time()} -- reading target grid")
grd <- qread("wp2-geobia/dat/interim/aoi/gaia_neo_grid.qs", nthreads = ncores)

wall("{Sys.time()} -- performing spatial join")
tic()
absence_area_sf <- st_as_sf(absence_area)
absence_area_sf <- absence_area_sf %>% mutate(neg_sample = TRUE)
absence_grid <- st_join(grd, absence_area_sf, join = st_intersects, left = TRUE)

# absence_grid_bcp <- absence_grid
absence_grid_bcp2 <- absence_grid

absence_grid <- absence_grid %>%
  select(-idx) %>%
  sfc_as_cols() %>%
  st_drop_geometry() %>%
  mutate(neg_sample = tidyr::replace_na(neg_sample, FALSE)) %>%
  select(neg_sample, x, y)
toc()

# table(absence_grid$neg_sample)
#    FALSE     TRUE 
#   5914642 23786348 

stopifnot(nrow(absence_grid) == nrow(grd))

wall("{Sys.time()} -- saving result")
qsave(absence_grid, "wp2-geobia/dat/interim/aoi/gaia_neo_absence_grid.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")

#st_write("wp2-geobia/dat/interim/aoi/gaia_neo_absence_grid.gpkg")

# #check
# tmp <- absence_grid %>%
#   st_as_sf(coords = c("x", "y"), crs = 3416)
# tmp %>%
#   filter(neg_sample == FALSE) %>%
#   st_write("wp2-geobia/dat/interim/aoi/nosample_grd.gpkg")
# tmp %>%
#   filter(neg_sample == TRUE) %>%
#   st_write("wp2-geobia/dat/interim/aoi/sample_grd.gpkg")

# table(tmp$neg_sample) #NOE:
# #    FALSE     TRUE 
# #  5914642 23786348 