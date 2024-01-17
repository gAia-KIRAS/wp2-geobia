import shutil
import os
from pathlib import Path

from osgeo import gdal

from grass_session import Session  # isort:skip
import grass.script as grass  # isort:skip

# get raster extent: upper left and lower right
src = gdal.Open("dat/interim/dtm_aoi/dtm_austria_carinthia.tif")
ulx, xres, xskew, uly, yskew, yres = src.GetGeoTransform()
lrx = ulx + (src.RasterXSize * xres)
lry = uly + (src.RasterYSize * yres)

# set up grass
grass_db = Path("dat/interim/grassdata/grass_db/")
# check if grass gis directory exists, create mapset if not
grass_perm = grass_db / "esa" / "PERMANENT"
if not grass_perm.exists():
    os.system(
        "grass -c 'dat/interim/dtm_aoi/dtm_austria_carinthia.tif' -e 'dat/interim/grassdata/grass_db/esa'"
    )
grassdata = grass_db / "esa" / "dtm"
if grassdata.exists():
    # remove old grass raster
    shutil.rmtree(str(grassdata))
# in grass session w/ new mapset
with Session(
    gisdb=str(grass_db),
    location="esa",
    mapset="dtm",
    create_opts="",
):
    # set region
    grass.run_command("g.region", n=uly, s=lry, e=lrx, w=ulx)
