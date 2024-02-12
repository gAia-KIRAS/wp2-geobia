# load packages
library("tidyverse")
library("sf")
library("tictoc")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Load data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# AOI
noe <- read_sf("dat/raw/aoi/gaia_projektgebiet_noe/NOE_gaiaArea.shp")

# GIP
st_layers("dat/raw/gip/gip_network_ogd.gpkg")
# EDGE_OGD: Einfach verständliche nicht routingfähige lineare Geometrie
# der GIP Abschnitte mit stabilen Ids und Versionierung
gip <- read_sf("dat/raw/gip/gip_network_ogd.gpkg", layer = "EDGE_OGD") %>%
  select(ACTION_ID, BAUSTATUS, SUBNETID:FRC, SHAPELENGTH:EDGECAT, MAINNAMETEXT, OWNER_ID, FEATURENAME, geom)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Clip data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# infrastructure
tic()
res <- gip %>%
  st_transform(crs = st_crs(noe)) %>%
  st_intersection(noe)
toc()
# 51.305 sec elapsed

st_write(res, dsn = "dat/interim/gip/noe.gpkg")
