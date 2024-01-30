#!/usr/bin/zsh

grassdir="dat/grassdata/grass_db/carinthia/esa"
outdir="dat/interim/effectively_surveyed_area"

raster="res_distance_rescaled"
#raster="res_numberofviews"
#raster="res_pointofviews"
#raster="res_viewangles"

grass ${grassdir} --exec r.out.gdal input=res_distance_rescaled output="${outdir}/${raster}.tif" format="GTiff" nodata=0

gdal_calc.py -A ${outdir}/${raster}.tif --outfile=${outdir}/${raster}_binary.tif --calc="A>0" --type "Byte"
