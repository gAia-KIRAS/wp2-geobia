#!/usr/bin/zsh

# write all files into input file list
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Create VRT input file list"
rm cfg/vrt_list_dtm_noe.txt
ls -A -1 -U -d dat/raw/dtm/dtm_noe/dtm_grd/* | grep -i "grd$" | sort > cfg/vrt_list_dtm_noe.txt

# fix crs chaos
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Consistently set EPSG:31256"
while read f; do
    gdal_edit.py -a_srs EPSG:31256 $f
done < cfg/vrt_list_dtm_noe.txt

# build virtual raster with gdal
echo "\n`date "+%Y-%m-%d %H:%M:%S"`: Build virtual raster:"
rm dat/interim/dtm/dtm_noe.vrt
gdalbuildvrt -a_srs epsg:31256 -input_file_list cfg/vrt_list_dtm_noe.txt dat/interim/dtm/dtm_noe.vrt
echo "`date "+%Y-%m-%d %H:%M:%S"`: Done"
