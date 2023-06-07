# --------------------------------------------------------------------------- #
# plain pandas dataframe
# --------------------------------------------------------------------------- #

import pyarrow as pa
import pandas as pd

with pa.memory_map("dat/processed/carinthia_10m.arrow", "rb") as src:
    data_xy = pa.ipc.open_file(src).read_all().to_pandas()

# --------------------------------------------------------------------------- #
# geopandas dataframe with simple feature column
# --------------------------------------------------------------------------- #

import geopandas as gpd

data_sfc = gpd.read_parquet("dat/processed/carinthia_10m.parquet")
