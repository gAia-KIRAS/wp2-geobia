library(sf)
library(dplyr)
library(qs)

ncores <- 30L

# AOI
aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea.shp") %>%
  st_transform(3416)

# AOI dataframe
grd <- qread("wp2-geobia/dat/interim/aoi/gaia_neo_grid.qs", nthreads = ncores)

# NOE
lithology <- read_sf("wp2-geobia/dat/raw/lithology/Lithologie_II.shp")  %>% 
  st_transform(3416)

lithology_mod <- lithology %>%
  select(-area, -ID, -count_sli) %>%
  mutate(Legend_fin = as.factor(Legend_fin))

#st_write(lithology_mod, "wp2-geobia/dat/raw/lithology/Lithologie_II_modified.shp")

lithology_reclass <- read_sf("wp2-geobia/dat/raw/lithology/Lithologie_II_classes.shp")  %>% 
  st_transform(3416)

lithology_clean <- lithology_reclass %>%
  mutate(
    lithology = as.integer(class),
    lithology_name = class.name
  ) %>%
  select(lithology, lithology_name, geometry)

res_lithology <- st_join(grd, lithology_clean)
#st_write(res_lithology, "wp2-geobia/dat/interim/misc_aoi/lithology_noe.gpkg", driver = "GPKG")

res_lithology_mod <- res_lithology %>%
  select(-idx) %>%
  mutate(lithology = as.factor(lithology))

qsave(res_lithology_mod, "wp2-geobia/dat/interim/misc_aoi/lithology_noe.qs", nthreads = ncores)
