#!/usr/bin/zsh

# crop dtm to aoi
# rm dat/interim/dtm_aoi/dtm_austria_carinthia.tif
# gdalwarp -cutline dat/raw/aoi/gaia_projektgebiet_ktn_union_3416.gpkg -crop_to_cutline \
#     dat/interim/dtm/dtm_austria.tif dat/interim/dtm_aoi/dtm_austria_carinthia.tif

grass -c "dat/interim/dtm_aoi/dtm_austria_carinthia.tif" -e "dat/interim/grassdata/grass_db/esa"

# create grass raster from dtm

# create grass inventory
