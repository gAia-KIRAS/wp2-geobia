# scale
cd ~/nfs_scratch/projekte/gAia/data/dem_derivates/ktn_Oberkaernten
for f in *.tif; 
    do gdal_translate -scale -co COMPRESS=LZW -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 -co BIGTIFF=YES $f ~/nfs_home/gAia/scaled/$f; 
done

cd ~/nfs_home/gAia/scaled
mkdir not_used4seg
mv dtm_carinthia_Oberkaernten_channel-network.tif not_used4seg/
mv dtm_carinthia_Oberkaernten_watershed-basins.tif not_used4seg/
mv dtm_carinthia_Oberkaernten_sinks-filled.tif not_used4seg/
mv dtm_carinthia_Oberkaernten_geomorphons.tif not_used4seg/

# stack
fname_stack=dtm_carinthia_Oberkaernten_scaled_stack.vrt
gdalbuildvrt -separate $fname_stack dtm_carinthia_Oberkaernten_*.tif

# prepare segmenting
cd ..
mkdir 02_segmented

# loop over subsets
for i in {1..4}
do
    subs=~/nfs_scratch/projekte/gAia/data/segments/ktn_Oberkaernten/ezg_subsets/subset$((i))_M31_bbox.shp
    stack_crop_file=scaled/"${fname_stack%.*}"_subset$i.tif
    gdalwarp -cutline $subs -crop_to_cutline -co BIGTIFF=YES -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 scaled/$fname_stack $stack_crop_file --config GDAL_CACHEMAX 16000
    otbcli_LargeScaleMeanShift -in $stack_crop_file -tilesizex 1023 -tilesizey 1023 \
        -mode.raster.out 02_segmented/lsms_r50_s50_ms5000_subs$i.tif -mode raster -spatialr 50 -ranger 50 -minsize 5000 \
        -ram 256 -cleanup 0 -outxml 02_segmented/saved_applications_parameters_s50_r50_subs$i.xml
done

# segmentation: spatialr = 50, ranger = 50
ulimit -n 5000
otbcli_LargeScaleMeanShift -in scaled/dtm_carinthia_Oberkaernten_scaled_stack.vrt -tilesizex 1023 -tilesizey 1023 \
    -mode.raster.out 02_segmented/lsms_r50_s50_ms5000.tif -mode raster -spatialr 50 -ranger 50 -minsize 5000 \
    -ram 256 -cleanup 0 -outxml 02_segmented/saved_applications_parameters_s50_r50.xml
