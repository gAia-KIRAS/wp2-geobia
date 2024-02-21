#!/usr/bin/zsh
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Prepare nDSM Dataset
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#
# Dataset:  Digitales Gelände- und Oberflächenmodell (5m) Kärnten 
#   - Sensing Method: Airborne Laserscanning
#   - CRS: Bundesmeldenetz M31 (EPSG:31258)
#   - Metadata: https://www.data.gv.at/katalog/de/dataset/digitales-gelandemodell-5m-karnten
#
# Reprojection:
#   - Using a Geographic Coordinate System would result in erroneous results in many DTM algorithms
#   - Reprojection to ERTS89 / Austria Lambert is performed only for
#     the sake of consistency with ZAMG's gridded climate data for Austria.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# input data
dsm=dat/raw/dtm/dgm_ktn/als_dom_5m.asc
dtm=dat/raw/dtm/dgm_ktn/als_dgm_5m.asc
wk=dat/interim/misc_aoi/wk_aoi_ktn.tif

# tmp and output
tmpdir=~/nfs_home/tmp
outfile=dat/interim/dtm_derivates/ktn/als_nDSM_10m.tif

# calc nDSM
gdal_calc.py -A $dsm -B $dtm --calc="A-B" --outfile=$tmpdir/als_nDSM_5m.tif --projectionCheck --NoDataValue=-9999

# reproject to EPSG:3416
gdalwarp -s_srs EPSG:31258 -t_srs EPSG:3416 -tr 10 10 -te 348650 300970 532540 359210 -tap -r average $tmpdir/als_nDSM_5m.tif $tmpdir/als_nDSM_10m.tif

# masking with forest map
gdal_calc.py -A $tmpdir/als_nDSM_10m.tif -B $wk --calc="A*(B>0)" --outfile=$outfile --projectionCheck --NoDataValue=-9999 --co="COMPRESS=LZW"
