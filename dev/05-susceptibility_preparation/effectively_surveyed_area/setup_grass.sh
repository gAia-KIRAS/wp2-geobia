#!/usr/bin/zsh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Perform initial GRASS setup: 
#   - creation of GRASS LOCATION and a PERMANENT mapset
#   - creation GRASS raster map
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

if [[ "$@" == "" || "$@" == *-h* || "$@" == *--help* ]]; then

    cat<<EOF
	
setup_grass.sh - Perform initial GRASS setup for computing effectively surveyed area:
    - creation of GRASS LOCATION and a PERMANENT mapset
    - creation GRASS raster map

Usage:
    setup_grass <grass_subdir> <base_dir> [<dem_raster>]
    setup_grass -h | --help

EOF

    exit 64

fi

set -e

# grass gis subdirectory
gis_dir=$1
if [[ -z $gis_dir ]]; then
    echo "No GRASS GIS directory given! First argument must be name of GRASS GIS directory!"
    exit
fi

# base directory for grass data
base_dir=$2
if [[ -z $geofile ]]; then
	base_dir="dat"
fi

grass_dir_base="${base_dir}/grassdata/grass_db"
grass_dir="${grass_dir_base}/${gis_dir}"
mkdir -p $grass_dir_base

# dem tif file
geofile=$3
if [[ -z $geofile ]]; then
	geofile="${base_dir}/interim/dtm_aoi/dtm_austria_${gis_dir}.tif"
fi

# create new location from vrt of tif file
echo "`date "+%Y-%m-%d %H:%M:%S"`: Create GRASS LOCATION from ${geofile} at ${grass_dir}"
grass -e -c ${geofile} ${grass_dir}

# check if directory exists
grassdir="${grass_dir}/PERMANENT/"
if [ -d "$grassdir" ]
then
	echo "`date "+%Y-%m-%d %H:%M:%S"`: Mapset PERMANENT successfully created at $grassdir."
else
	echo "`date "+%Y-%m-%d %H:%M:%S"`: ERROR: $grassdir not found. Please check GRASS location."
	exit
fi

# link GDAL supported raster data as a pseudo GRASS raster map  
echo "`date "+%Y-%m-%d %H:%M:%S"`: Link virtual raster as pseudo GRASS raster"
grass ${grassdir} --exec r.external input=${geofile} output=dem

# create grass inventory
