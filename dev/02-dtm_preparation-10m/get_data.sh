#!/usr/bin/zsh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Prepare DTM Dataset
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#
# Dataset: Digital Terrain Model from Austria
#   - Sensing Method: Airborne Laserscanning
#   - CRS: MGI / Austria Lambert (EPSG:31287)
#   - Metadata: https://www.data.gv.at/katalog/dataset/land-ktn_digitales-gelandemodell-dgm-osterreich
#
# Reprojection:
#   - Using a Geographic Coordinate System would result in erroneous results in many DTM algorithms
#   - The Austrian DTM is available in MGI / Austria Lambert (EPSG:31287).
#     Reprojection to ERTS89 / Austria Lambert is performed only for
#     the sake of consistency with ZAMG's gridded climate data for Austria.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Metadata
curl "https://www.data.gv.at/katalog/api/3/action/package_show?id=b5de6975-417b-4320-afdb-eb2a9e2a1dbf" > doc/dtm_metadata.json

# Downlaod and unzip GeoTIFF
wget https://gis.ktn.gv.at/OGD/Geographie_Planung/ogd-10m-at.zip -P dat/raw/dtm/dtm_at_10m/
unzip dat/raw/dtm/dtm_at_10m/ogd-10m-at.zip -d dat/raw/dtm/dtm_at_10m/

# Reproject to common coordinate reference system
# t_srs=$(cat cfg/wkt_3416.prj | egrep -v "(^#.*|^$)")
gdalwarp -s_srs EPSG:31287 -t_srs EPSG:3416 -dstnodata "-9999" \
    -tr 10 10 -te 108815 268555 689435 586505 \
    dat/raw/dtm/dtm_at_10m/dhm_at_lamb_10m_2018.tif dat/interim/dtm/dtm_austria.tif
