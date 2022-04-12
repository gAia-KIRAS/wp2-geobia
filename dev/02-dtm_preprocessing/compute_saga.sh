#!/usr/bin/zsh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# SAGA-based terrain analysis
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# SAGA Tool Library Overview
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/index.html
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Terrain Analysis Libraries
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology.html
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry.html
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_slope_stability.html
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_lighting.html
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# source definition of target file / aoi region
source cfg/aoi_config.sh

# check
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: working on '${target_file}'"
if [ ! -f dat/interim/dtm/${target_file}.tif ]; then
    echo "File not found. Please check 'dat/interim/dtm/${target_file}.tif'." >&2
    exit 1
fi

# create saga raster data set
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Convert GeoTIFF to SAGA GIS Binary Grid File Format"
gdal_translate -of SAGA dat/interim/dtm/${target_file}.tif \
  dat/interim/sagadata/${target_file}.sdat

# setup file paths
dtm_elev="dat/interim/sagadata/${target_file}.sdat"
outpath_base="dat/interim/sagadata/${target_file}"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables - preprocessing
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Slope (RAD)
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_0.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Slope (RAD)"
saga_cmd ta_morphometry 0 -ELEVATION $dtm_elev \
    -SLOPE "${outpath_base}_slope-rad.sdat"

# Fill Surface Depressions
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_preprocessor_4.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Fill Sinks"
saga_cmd ta_preprocessor 4 -ELEV $dtm_elev \
    -FILLED "${outpath_base}_sinks-filled.sdat"

# setup file paths
dtm_slope="${outpath_base}_slope-rad.sdat"
dtm_nosinks="${outpath_base}_sinks-filled.sdat"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables - hydrology
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Flow Accumulation / Catchment Area & Accumulated Material
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology_0.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Flow Accumulation"
saga_cmd ta_hydrology 0 -ELEVATION $dtm_nosinks \
    -FLOW "${outpath_base}_flow-accumulation.sdat"

# Melton Ruggedness Number
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology_23.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Melton Ruggedness Number"
saga_cmd ta_hydrology 23 -DEM $dtm_elev \
    -AREA "${outpath_base}_catchment-area.sdat" \
    -ZMAX "${outpath_base}_maximum-height.sdat" \
    -MRN "${outpath_base}_MRN.sdat"

# Flow Path Length
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology_6.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Flow Path Length"
saga_cmd ta_hydrology 6 -ELEVATION $dtm_nosinks \
    -LENGTH "${outpath_base}_flow-path-length.sdat"

# Flow Width and Specific Catchment Area
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology_19.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Flow Path Width / SCA"
saga_cmd ta_hydrology 19 -DEM $dtm_nosinks -TCA "${outpath_base}_catchment-area.sdat" \
    -WIDTH "${outpath_base}_flow-width.sdat" \
    -SCA "${outpath_base}_SCA.sdat"

# Stream Power Index
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology_21.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Stream Power Index"
saga_cmd ta_hydrology 21 -SLOPE $dtm_slope -AREA "${outpath_base}_SCA.sdat" \
    -SPI "${outpath_base}_SPI.sdat"

# SAGA Wetness Index
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_hydrology_15.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Topographic Wetness Index"
saga_cmd ta_hydrology 15 -DEM $dtm_nosinks \
    -AREA_MOD "${outpath_base}_mod-catchment-area.sdat" \
    -TWI "${outpath_base}_TWI.sdat"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables - watershed delineation
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Channel Network
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_channels_0.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Channel Network"
saga_cmd ta_channels 0 -ELEVATION $dtm_nosinks \
    -INIT_GRID "${outpath_base}_flow-accumulation.sdat" \
    -CHNLNTWRK "${outpath_base}_channel-network.sdat" \
    -INIT_VALUE 10000000 \
    -INIT_METHOD "2"

# Watershed Basins
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_channels_0.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Watershed Basins"
saga_cmd ta_channels 1 -ELEVATION $dtm_nosinks \
    -CHANNELS "${outpath_base}_channel-network.sdat" \
    -BASINS "${outpath_base}_watershed-basins.sdat"

# Vectorize Grid Classes
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/shapes_grid_6.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Vectorize Basin Grids"
saga_cmd shapes_grid 6 -GRID "${outpath_base}_watershed-basins.sdat" \
    -POLYGONS "${outpath_base}_watershed-basins.gpkg" 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables - morphometry
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Curvature
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_0.html
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_23.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Curvature"
saga_cmd ta_morphometry 23 -DEM $dtm_elev \
    -MINIC "${outpath_base}_curv-min.sdat" \
    -MAXIC "${outpath_base}_curv-max.sdat" \
    -PLANC "${outpath_base}_curv-plan.sdat" \
    -PROFC "${outpath_base}_curv-prof.sdat"

# Normalized Height
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_14.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Normalized Height"
saga_cmd ta_morphometry 14 -DEM $dtm_elev \
    -NH "${outpath_base}_NH.sdat" -W=5 -T=2 -E=2

# Convergence Index
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_1.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Convergence Index"
saga_cmd ta_morphometry 1 -ELEVATION $dtm_elev \
    -RESULT "${outpath_base}_convergence-index.sdat"

# Vector Ruggedness Measure
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_17.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Vector Ruggedness Measure"
saga_cmd ta_morphometry 17 -DEM $dtm_elev \
    -VRM "${outpath_base}_VRM.sdat"

# Terrain Surface Convexity
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_21.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Terrain Surface Convexity"
saga_cmd ta_morphometry 21 -DEM $dtm_elev \
    -CONVEXITY "${outpath_base}_convexity.sdat"

# Diurnal Anisotropic Heat
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_12.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Diurnal Anisotropic Heat"
saga_cmd ta_morphometry 12 -DEM $dtm_elev \
    -DAH "${outpath_base}_DAH.sdat"

# Hypsometry (Hypsometric Curve)
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_5.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Hypsometric Curve"
saga_cmd ta_morphometry 5 -ELEVATION $dtm_elev \
    -TABLE "${outpath_base}_hypsometry.csv"

# Terrain surface classification based on terrain surface convexity
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_22.html
# Landform classification based on the profile and tangential (across slope) curvatures
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_4.html
# Fuzzy landform element classification
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry_25.html

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables - lighting
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Geomorphons
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_lighting_8.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Geomorphons"
saga_cmd ta_lighting 8 -DEM $dtm_elev \
    -GEOMORPHONS "${outpath_base}_geomorphons.sdat"

# Sky View Factor
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_lighting_3.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute SVF"
saga_cmd ta_lighting 3 -DEM $dtm_elev \
    -SVF "${outpath_base}_SVF.sdat"

# Topographic Openness
# https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_lighting_5.html
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Compute Topographic Openness"
saga_cmd ta_lighting 5 -DEM $dtm_elev \
    -POS "${outpath_base}_PTO.sdat" \
    -NEG "${outpath_base}_NTO.sdat"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# land-surface variables - slope stability
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# TODO

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# prepare final output
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# convert saga raster data sets back to geotiff
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Convert SAGA GIS Binary Grid File Format back to GeoTIFF"
cd dat/interim/sagadata
for s in *.sdat; do 
  echo "------------------------------------------------------------"
  t=$(echo $s | sed 's/\.sdat$/.tif/')
  if [[ "$s" == "${target_file}.sdat" ]]; then
      continue
  fi
  gdal_translate -of GTiff $s ../../output/$t
  echo "converted '$s' >> '$t'"
done
cd ....

echo "`date "+%Y-%m-%d %H:%M:%S"`: Done"
