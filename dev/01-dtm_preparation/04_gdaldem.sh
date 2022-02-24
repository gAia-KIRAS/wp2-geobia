#!/usr/bin/zsh

target_file="test_aoi_ktn"

# compute slope
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute slope"
gdaldem slope -compute_edges dat/interim/dtm/${target_file}.tif dat/interim/dtm_derivates/${target_file}_slope.tif

# compute aspect
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute aspect"
gdaldem aspect -compute_edges dat/interim/dtm/${target_file}.tif dat/interim/dtm_derivates/${target_file}_aspect.tif

# compute TRI
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute TRI"
gdaldem TRI -compute_edges dat/interim/dtm/${target_file}.tif dat/interim/dtm_derivates/${target_file}_tri.tif

# compute TPI
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute TPI"
gdaldem TPI -compute_edges dat/interim/dtm/${target_file}.tif dat/interim/dtm_derivates/${target_file}_tpi.tif

# compute roughness
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: compute roughness"
gdaldem roughness -compute_edges dat/interim/dtm/${target_file}.tif dat/interim/dtm_derivates/${target_file}_roughness.tif
