#!/usr/bin/env python
"""Calculate GRASS derivatives from DTM."""

import shutil
from pathlib import Path

from osgeo import gdal
from grass_session import Session
import grass.script as grass

gis_dir = "test"
aoi_tif = "test_aoi_ktn.tif"
overwrite = True

src = gdal.Open(f"dat/interim/dtm/{aoi_tif}")
ulx, xres, xskew, uly, yskew, yres = src.GetGeoTransform()
lrx = ulx + (src.RasterXSize * xres)
lry = uly + (src.RasterYSize * yres)
scr = None

with Session(
    gisdb="dat/grassdata",
    location=gis_dir,
    mapset="dtm",
    create_opts="",
):
    # set region
    grass.run_command("g.region", n=uly, s=lry, e=lrx, w=ulx)

    # compute stuff here
    grass.run_command(
        "r.horizon",
        input="dtm",
        output="dtm_svf",
        ndir=32,
        overwrite=overwrite,
        quiet=True,
    )

    # export GeoTIFF
    grass.run_command(
        "r.out.gdal",
        input=f"dtm_svf",
        output=f"dat/interim/dtm_derivates/{gis_dir}/dtm_sfv.tif",
        format="GTiff",
        type="Float32",
        createopt="COMPRESS=ZSTD,ZSTD_LEVEL=1,PREDICTOR=3",
        flags="c",
        quiet=True,
    )
