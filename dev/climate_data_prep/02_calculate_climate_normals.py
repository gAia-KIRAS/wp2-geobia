"""Calculate climate normals for the use in clustering"""

from pathlib import Path

import numpy as np
from scipy.ndimage.filters import generic_filter as gen_filter
import xarray as xr


def filter_nanmean(da_: xr.DataArray, size: int = 20):
    """2d filter to be applied on the input xr.DataArray with
    a 2d box side length defined by size."""
    da_in = da_.copy()
    da_list = []
    for var_iter in da_in["variable"]:
        da_iter = da_in.sel(variable=var_iter)
        da_iter.data = gen_filter(da_iter, np.nanmean, size=size, mode="nearest")
        da_list.append(da_iter)
    da_out = xr.concat(da_list, dim="variable")
    return da_out.where(~np.isnan(da_), np.nan)


if __name__ == "__main__":

    filter_ = True

    data_dir = Path("dat/raw/grid/obs")
    tmp_dir = Path("dat/interim")

    clim_period = slice("01-01-1991", "31-12-2020")
    clim_str = "01-01-1991 to 31-12-2020"

    data_list = []
    for file in Path(tmp_dir, "01_concat_files").rglob("*concat*.nc"):
        print(f"..Processing {file.name = }..")
        with xr.load_dataarray(file) as da_load:
            if file.name == "dtm_concat_indices.nc":
                # dtm data is time invariant, hence is just the input data
                clim_mean = da_load.copy()
            else:
                # else for all other data for which climate normals can be calculated
                clim_mean = da_load.sel(time=clim_period).mean(dim="time")
                clim_std = da_load.sel(time=clim_period).std(dim="time")

            clim_mea1 = clim_mean.assign_coords(
                {"climate_period": clim_str, "metric": "mean"}
            )
            clim_std = clim_std.assign_coords(
                {"climate_period": clim_str, "metric": "std"}
            )

            if not file.name == "misc_concat_snowgrid_indices.nc":
                # grab grid for spartacus v2.1 that is needed for later snowgrid
                # interpolation
                ds_grid_out = xr.Dataset(
                    {
                        "x": (["x"], da_load.coords["x"].values),
                        "y": (["y"], da_load.coords["y"].values),
                    }
                )
            else:
                # inteprolate snowgrid from sparta v1.5 grid to v2.1
                ds_grid_in = xr.Dataset(
                    {
                        "x": (["x"], da_load.coords["x"].values),
                        "y": (["y"], da_load.coords["y"].values),
                    }
                )
                # pylance complains, but ds_grid_out will always exist
                # because of the way the files are globbed
                clim_mean = clim_mean.interp_like(ds_grid_out)
                clim_std = clim_std.interp_like(ds_grid_out)

            if not file.name == "dtm_concat_indices.nc":
                # smooth field because of technical vs. physical resolution
                # for all calculated indices (not dtm data)
                # https://vgitlab.zamg.ac.at/zamg-cit/tools/subregion_derivation/-/issues/4
                if filter_:
                    clim_mean = filter_nanmean(clim_mean)
                    clim_std = filter_nanmean(clim_std)

            data_iter_fin = xr.concat([clim_mean, clim_std], dim="metric")
            data_list.append(data_iter_fin)

    print("..Concatenating data..")
    da_merged = xr.concat(data_list, dim="variable")
    new_par_dir = Path(tmp_dir, "02_preprocessed_climate_normals")
    new_par_dir.mkdir(exist_ok=True, parents=True)
    print("..Saving data..")
    if filter_:
        da_merged.to_netcdf(Path(new_par_dir, "indicators_climate_normals.nc"))
    else:
        da_merged.to_netcdf(
            Path(new_par_dir, "indicators_climate_normals_unfiltered.nc")
        )
