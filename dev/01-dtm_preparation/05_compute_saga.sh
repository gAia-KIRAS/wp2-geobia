#!/usr/bin/zsh

# source definition of target file / aoi region
source cfg/aoi_config.sh

# create saga raster data set
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Convert GeoTIFF to SAGA GIS Binary Grid File Format"
gdal_translate -of SAGA dat/interim/dtm/${target_file}.tif dat/interim/dtm/${target_file}.sdat

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# curvature
# https://saga-gis.sourceforge.io/saga_tool_doc/7.1.0/ta_morphometry_0.html
# https://saga-gis.sourceforge.io/saga_tool_doc/7.1.0/ta_morphometry_23.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Curvature"
saga_cmd ta_morphometry 23 -DEM "dat/interim/dtm/${target_file}.sdat" \
    -MINIC "dat/interim/dtm_derivates/${target_file}_curv-min.sdat" \
    -MAXIC "dat/interim/dtm_derivates/${target_file}_curv-max.sdat" \
    -PLANC "dat/interim/dtm_derivates/${target_file}_curv-plan.sdat" \
    -PROFC "dat/interim/dtm_derivates/${target_file}_curv-prof.sdat"

# flow accumulation
# https://saga-gis.sourceforge.io/saga_tool_doc/7.0.0/ta_hydrology_0.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Flow Accumulation"
saga_cmd ta_hydrology 0 -ELEVATION "dat/interim/dtm/${target_file}.sdat" \
    -FLOW "dat/interim/dtm_derivates/${target_file}_flow-accumulation.sdat" \
    -ACCU_TOTAL "dat/interim/dtm_derivates/${target_file}_accumulated-material.sdat" \

# compute normalized height
# https://saga-gis.sourceforge.io/saga_tool_doc/7.1.0/ta_morphometry_14.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Normalized Height"
saga_cmd ta_morphometry 14 -DEM "dat/interim/dtm/${target_file}.sdat" \
    -HN "dat/interim/dtm_derivates/${target_file}_hn.sdat" -W=5 -T=2 -E=2

# compute SWI
# https://saga-gis.sourceforge.io/saga_tool_doc/7.1.0/ta_hydrology_15.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute SWI"
saga_cmd ta_hydrology 15 -DEM "dat/interim/dtm/${target_file}.sdat" \
    -TWI "dat/interim/dtm_derivates/${target_file}_swi.sdat"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# shape metrics
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# TODO

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# prepare final output
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# convert saga raster data sets back to geotiff
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Convert SAGA GIS Binary Grid File Format back to GeoTIFF"
cd dat/interim/dtm_derivates
for s in *.sdat; do 
  t=$(echo $s | sed 's/\.sdat$/.tif/');
  gdal_translate -of GTiff $s $t
  "converted '$s' >> '$t'"
done
cd ....

echo "`date "+%Y-%m-%d %H:%M:%S"`: Done"
