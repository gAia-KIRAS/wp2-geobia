# load packages
library("tidyverse")
library("sf")
library("tictoc")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Load data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# AOI
ktn <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg")

# GIP
st_layers("dat/raw/gip/gip_network_ogd.gpkg")
# EDGE_OGD: Einfach verständliche nicht routingfähige lineare Geometrie
# der GIP Abschnitte mit stabilen Ids und Versionierung
gip <- read_sf("dat/raw/gip/gip_network_ogd.gpkg", layer = "EDGE_OGD") %>%
  select(ACTION_ID, BAUSTATUS, SUBNETID:FRC, SHAPELENGTH:EDGECAT, MAINNAMETEXT, OWNER_ID, FEATURENAME, geom)

# Gesamtgewaessernetz
ggn <- read_sf("dat/raw/ggn/Routen.shp") %>%
  st_zm()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Clip data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# water bodies
ggn %>%
  filter(grepl("Kärnten", BUNDESL)) %>%
  st_transform(crs = st_crs(ktn)) %>%
  st_intersection(ktn) %>%
  select(-RICHTL, -AUSL_ANT, -area) %>%
  rename(AOI = name) %>%
  st_write(dsn = "dat/interim/ggn/kaernten.gpkg")

# infrastructure
tic()
res <- gip %>%
  st_transform(crs = st_crs(ktn)) %>%
  st_intersection(ktn)
toc()
# 939.647 sec elapsed

st_write(res, dsn = "dat/interim/gip/kaernten.gpkg")
