import xarray as xr
from inca import INCA_to_netCDF
import geopandas as gpd
import rioxarray
import glob
import matplotlib.pyplot as plt


def load_inca_and_compute_daily_agg(path: str, parameter: str, period: str):
    """diese Funktion liest für den gegebenen Parameter die INCA Daten ein
    und aggregiert diese - abhängig vom Parameter - auf Tagesbasis.
    Dies wird immer nur für ein halbes Jahr durchgeführt, da es sonst
    zu RAM Problemen kommen kann. Beim Druck verfälscht der Fill Value -9999
    das Tagesmittel, daher wird dieser ohne Fill Value abgespeichert; die
    einzelnen Dateien sind daher größer.

    Args:
        path (str): Pfad wohin Daten abgespeichert werden sollen
        parameter (str): betrachteter Parameter
        period (str): Zeitraum (erstes oder zweites Halbjahr)
    """
    if period == "2017":
        ds = INCA_to_netCDF("2017090100", "2017123123", "L", param, path)
        if (
            parameter == "mslp"
            or parameter == "relative_humidity"
            or parameter == "temp"
        ):
            ds_agg = ds.resample(time="1D").mean("time")
        if parameter == "wind" or parameter == "gust":
            ds_agg = ds.resample(time="1D").max("time")
        if parameter == "prec":
            ds_agg = ds.resample(time="1D").sum("time")

        if paramater == "mslp":
            encoding = {
                parameter: {
                    "dtype": "int16",
                    "scale_factor": 0.1,
                    "zlib": True,
                    "complevel": 9,
                }
            }
        else:
            encoding = {
                parameter: {
                    "dtype": "int16",
                    "scale_factor": 0.1,
                    "_FillValue": -9999,
                    "zlib": True,
                    "complevel": 9,
                }
            }

        ds_agg.to_netcdf(
            f"{path}/{parameter}/INCA_2017090100_20171231_23_{parameter}.nc",
            engine="h5netcdf",
        )

    else:
        for year in ["2018", "2019", "2020", "2021", "2022"]:
            if period == "first_half":
                ds = INCA_to_netCDF(year + "010100", year + "063023", "L", param, path)
            else:
                ds = INCA_to_netCDF(year + "070100", year + "123123", "L", param, path)
            if (
                parameter == "mslp"
                or parameter == "relative_humidity"
                or parameter == "temp"
            ):
                ds_agg = ds.resample(time="1D").mean("time")
            if parameter == "wind" or parameter == "gust":
                ds_agg = ds.resample(time="1D").max("time")
            if parameter == "prec":
                ds_agg = ds.resample(time="1D").sum("time")

            if paramater == "mslp":
                encoding = {
                    parameter: {
                        "dtype": "int16",
                        "scale_factor": 0.1,
                        "zlib": True,
                        "complevel": 9,
                    }
                }
            else:
                encoding = {
                    parameter: {
                        "dtype": "int16",
                        "scale_factor": 0.1,
                        "_FillValue": -9999,
                        "zlib": True,
                        "complevel": 9,
                    }
                }

            if period == "first_half":
                ds_agg.to_netcdf(
                    f"{path}/{parameter}/INCA_{year}010100_{year}063023_{parameter}.nc",
                    engine="h5netcdf",
                )
            else:
                ds_agg.to_netcdf(
                    f"{path}/{parameter}/INCA_{year}070100_{year}123123_{parameter}.nc",
                    engine="h5netcdf",
                )


def cut_aoi(path: str, param: str) -> xr.DataArray:
    """Diese Funktion liest die in der obigen Funktion generierten Tagesmittel ein,
    weist dem Dataarray die richtige Projektion zu und schneidet die Zielregion aus.
    Der resultierende Dataarray wird wieder als .nc Datei abgespeichert.

    Args:
        path (str): Pfad wo Daten liegen und wo abgespeichert wird
        param (str): betrachteter Parameter

    Returns:
        xr.DataArray: Dataarray des betrachteten Parameters für die Zielregion
    """
    ds = xr.open_mfdataset(path + "/" + param + "/*.nc")
    da = ds[param]
    da.rio.write_crs("EPSG:31287", inplace=True)
    gdf_aoi = gpd.read_file("/cmod3/projects/gaia/dat/AOI_Kaernten.gpkg")
    da_cut = da.rio.clip(gdf_aoi.geometry.values, gdf_aoi.crs, drop=True, invert=False)
    da_cut.to_netcdf(f"{path}/dat/final/INCA_09-2017_12-2022_{param}.nc")
    return da_cut


if __name__ == "__main__":
    for param in ["mslp", "relative_humidity", "prec", "wind", "gust", "temp"]:
        load_inca_and_compute_daily_agg("/cmod3/projects/gaia/", param, "second_half")
        ds = cut_aoi("/cmod3/projects/gaia/", param)
