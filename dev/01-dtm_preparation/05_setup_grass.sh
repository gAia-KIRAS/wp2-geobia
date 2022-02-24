#!/usr/bin/zsh

# grass gis subdirectory
gis_dir="test"
template_file="test_aoi_ktn.tif"

# create new location from dtm file
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Create GRASS LOCATION from DTM"
grass -c dat/interim/dtm/${template_file} dat/grassdata/${gis_dir}

# check if directory exists
grassdir="dat/grassdata/${gis_dir}/PERMANENT/"
if [ -d "$grassdir" ]
then
	echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Mapset PERMANENT successfully created at $grassdir."
else
	echo "\n`date "+%Y-%m-%d %H:%M:%S"`: ERROR: $grassdir not found. Please check GRASS location."
fi

# link GDAL supported raster data as a pseudo GRASS raster map  
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Link gdal supported raster as pseudo GRASS raster"
grass dat/grassdata/${gis_dir}/PERMANENT/ --exec r.external input=dat/interim/dtm/${template_file} output=dtm
