import shutil
import os
from pathlib import Path

from osgeo import gdal

from grass_session import Session  # isort:skip
import grass.script as grass  # isort:skip
dem = "dat/interim/dtm_aoi/dtm_austria_carinthia.tif"

# get raster extent: upper left and lower right
src = gdal.Open(dem)
ulx, xres, xskew, uly, yskew, yres = src.GetGeoTransform()
lrx = ulx + (src.RasterXSize * xres)
lry = uly + (src.RasterYSize * yres)

# set up grass
grass_db = Path("dat/grassdata/grass_db/")
# check if grass gis directory exists, create mapset if not
grass_perm = grass_db / "effectively_surveyed_area" / "PERMANENT"
if not grass_perm.exists():
    os.system(f"grass -c {dem} -e 'dat/grassdata/grass_db/effectively_surveyed_area'")
grassdata = grass_db / "effectively_surveyed_area" / "esa"
if grassdata.exists():
    # remove old grass raster
    shutil.rmtree(str(grassdata))
# in grass session w/ new mapset
with Session(
    gisdb=str(grass_db),
    location="effectively_surveyed_area",
    mapset="esa",
    create_opts="",
):
    # set region
    grass.run_command("g.region", n=uly, s=lry, e=lrx, w=ulx)
