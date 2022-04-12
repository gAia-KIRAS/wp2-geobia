#!/usr/bin/zsh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Essential gdal-based DEM derivates
# https://gdal.org/programs/gdaldem.html
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# source definition of target file / aoi region
source cfg/aoi_config.sh

# check
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: working on '${target_file}'"
if [ ! -f dat/interim/dtm/${target_file}.tif ]; then
    echo "File not found. Please check 'dat/interim/dtm/${target_file}.tif'." >&2
    exit 1
fi

# slope
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute slope"
gdaldem slope -compute_edges dat/interim/dtm/${target_file}.tif \
  dat/output/${target_file}_slope.tif

# aspect
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute aspect"
gdaldem aspect -compute_edges dat/interim/dtm/${target_file}.tif \
  dat/output/${target_file}_aspect.tif

# TRI
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute TRI"
gdaldem TRI -compute_edges dat/interim/dtm/${target_file}.tif \
  dat/output/${target_file}_tri.tif

# TPI
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute TPI"
gdaldem TPI -compute_edges dat/interim/dtm/${target_file}.tif \
  dat/output/${target_file}_tpi.tif

# roughness
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute roughness"
gdaldem roughness -compute_edges dat/interim/dtm/${target_file}.tif \
  dat/output/${target_file}_roughness.tif

echo "\n`date "+%Y-%m-%d %H:%M:%S"`: done"

