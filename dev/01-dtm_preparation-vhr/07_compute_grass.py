#!/usr/bin/env python
"""Calculate GRASS derivatives from DTM."""

import shutil
from pathlib import Path

from osgeo import gdal
from grass_session import Session
import grass.script as grass


# Setup  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

gis_dir = "dtm_location"
aoi_tif = "test_aoi.tif"
overwrite = True


# Helper functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


def export_geotiff(input_raster, output_path):
    """Export GRASS GIS raster to GeoTIFF."""
    grass.run_command(
        "r.out.gdal",
        input=input_raster,
        output=output_path,
        format="GTiff",
        type="Float32",
        createopt="COMPRESS=ZSTD,ZSTD_LEVEL=1,PREDICTOR=3",
        flags="c",
        quiet=True,
    )
    print(f"Exported {input_raster} as {output_path}")


# Setup region ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


src = gdal.Open(f"dat/interim/dtm/{aoi_tif}")
ulx, xres, xskew, uly, yskew, yres = src.GetGeoTransform()
lrx = ulx + (src.RasterXSize * xres)
lry = uly + (src.RasterYSize * yres)
scr = None


# Compute w/ GRASS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


with Session(
    gisdb="dat/interim/grassdata",
    location=gis_dir,
    mapset="dtm",
    create_opts="",
):
    # set region
    grass.run_command("g.region", n=uly, s=lry, e=lrx, w=ulx)

    # compute texture
    # https://grass.osgeo.org/grass78/manuals/r.texture.html
    grass.run_command(
        "r.texture",
        input="dtm",
        output="dtm_texture",
        size=3,
        method="entr",
        overwrite=overwrite,
        quiet=True,
    )
    export_geotiff("dtm_texture_Entr", "dat/output/dtm_texture_entropy.tif")

    # compute skyview factor
    # https://grass.osgeo.org/grass78/manuals/addons/r.skyview.html
    grass.run_command(
        "r.skyview",
        input="dtm",
        output="dtm_svf",
        ndir=32,
        overwrite=overwrite,
        quiet=True,
    )

    # export GeoTIFF
    export_geotiff("dtm_svf", "dat/output/dtm_sfv.tif")
