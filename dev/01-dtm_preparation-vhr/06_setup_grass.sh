#!/usr/bin/zsh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Setup GRASS GIS Database
# https://grass.osgeo.org/grass80/manuals/grass_database.html
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# A GRASS GIS Database is simply a set of directories and files with certain
# structure which GRASS GIS works efficiently with. Location is a directory
# with data related to one geographic location or a project. All data within
# one Location has the same cartographic projection. A Location contains
# Mapsets and each Mapset contains data related to a specific task, user or a
# smaller project.  Within each Location, a mandatory PERMANENT Mapset exists
# which can contain commonly used data within a Location such as base maps.
# PERMANENT Mapset also contains metadata related to Location such as
# projection. When GRASS GIS is started it connects to a Database, Location
# and Mapset specified by the user. 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# source definition of target file / aoi region
source cfg/aoi_config.sh

# create new location from dtm file
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Create GRASS LOCATION from DTM"
grass -c dat/interim/dtm/${target_file}.tif -e dat/interim/grassdata/${gis_dir}

# check if directory exists
grassdir="dat/interim/grassdata/${gis_dir}/PERMANENT/"
if [ -d "$grassdir" ]
then
    echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Mapset PERMANENT successfully created at $grassdir."
else
    echo "\n`date "+%Y-%m-%d %H:%M:%S"`: ERROR: $grassdir not found. Please check GRASS location."
fi

# link GDAL supported raster data as a pseudo GRASS raster map  
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Link gdal supported raster as pseudo GRASS raster"
grass dat/interim/grassdata/${gis_dir}/PERMANENT/ --exec r.external \
  input=dat/interim/dtm/${target_file}.tif output=dtm
