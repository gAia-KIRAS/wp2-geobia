import xarray as xr
from pathlib import Path
import geopandas as gpd

path_in = Path("/cmod3/projects/subregion_derivation/tmp/01_concat_files/")
path_out = Path("/cmod3/projects/gaia/dat/final/")


vars_climdex = ["CWD", "PRCPTOT", "SDII", "Rx5day", "RRRx1day"]
vars_sparta_winfore = [
    "api_p0.935_k7_yearpctl95",
    "api_p0.935_k30_yearpctl95",
    "SPEI30_yearpctl95",
    "pci",
]
climate_normal_begin = "1991-01-01"
climate_normal_end = "2020-12-31"
gdf_aoi = gpd.read_file("/cmod3/projects/gaia/dat/AOI_Kaernten.gpkg").to_crs(3416)


for filename in [
    "climdex_concat_indices.nc",
    "misc_concat_spartacus_winfore_indices.nc",
]:
    if filename == "climdex_concat_indices.nc":
        ds = xr.open_dataset(path_in / filename)
        ds_sel = ds.sel(
            variable=vars_climdex, time=slice(climate_normal_begin, climate_normal_end)
        )
        ds_sel_q95 = ds_sel.quantile(0.95, dim="time")
        ds_sel_q95.rio.write_crs("EPSG:3416", inplace=True)
        ds_sel_q95_cut = ds_sel_q95.rio.clip(
            gdf_aoi.geometry.values, gdf_aoi.crs, drop=True, invert=False
        )
        ds_sel_q95_cut.to_netcdf(path_out / "climdex_indices_mean_q95.nc")

    elif filename == "misc_concat_spartacus_winfore_indices.nc":
        ds = ds = xr.open_dataset(path_in / filename)
        ds_sel = ds.sel(
            variable=vars_sparta_winfore,
            time=slice(climate_normal_begin, climate_normal_end),
        )
        ds_sel_mean = ds_sel.mean(dim="time")
        ds_sel_mean.rio.write_crs("EPSG:3416", inplace=True)
        ds_sel_mean_cut = ds_sel_mean.rio.clip(
            gdf_aoi.geometry.values, gdf_aoi.crs, drop=True, invert=False
        )
        ds_sel_mean_cut.to_netcdf(path_out / "api_spei_pci_indices_q95_mean.nc")
