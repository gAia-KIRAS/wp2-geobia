#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May 14 13:08:38 2020
@author: kathi_eni
"""


# von Martin Kulmer zur Verfuegung gestellt bekommen
def read_INCA_ascii(fname, dt, dom="L", twodim=False, verbose=True, single_point=None):
    """
    With this function an INCA file of "asc" type is read in. The domain
    size is chosen via the "dom" keyword (default: L(arge)). If the file
    name contains ".gz" the reading is done through the gzip library. If
    the file name contains ".zip" it is assumed that we read parameter
    GUST, which additionally triggers a loop over 6 individual 10 minute
    intervals and checks for the maximum at each individual grid point.

    IN: path and name of INCA file (either gzipped or not)
        dom (optional): L or AT (small INCA domain) or SK or CZ
        twodim (boolean, optional): return the horizontal information as
            single dimension (2D = False)
        single_point (integer, optional): return only one the value at a
            given index

    OUT: Numpy array or value
    """
    import numpy as np
    import gzip
    from zipfile import ZipFile
    import os
    import glob

    if dom == "L":
        nx = 701  # east west grid points
        ny = 401  # north south grid points
        nb = 70  # number of "blocks" in ASCII file
    elif dom == "ALBINA":
        nx = 701
        ny = 431
        nb = 70
    elif dom == "AT":
        nx = 601
        ny = 351
        nb = 60
    elif dom == "SK":
        nx = 501
        ny = 301
        nb = 50
    elif dom == "CZ":
        nx = 531
        ny = 301
        nb = 50

    else:
        print("Domain not specified. Giving up on that one!")
        return None

    if verbose:
        if twodim == True:
            print("  Data is returned as array with dimensions " + "(n_level, nj, ni)")
        else:
            print("  Data is returned as array with dimensions " + "(n_level, nj * ni)")

    if not glob.glob(fname):
        print("Could not find file " + fname)
        return None
    else:
        if verbose:
            print("  input file:", fname)

    if single_point is not None and twodim is True:
        print("With single_point argument set, twodim has to be False!")
        return None

    if ".gz" in fname:
        f = gzip.open(fname, "rb")
    elif ".zip" in fname:
        f = ZipFile(fname)
    else:
        f = open(fname, "r")

    if ".zip" in fname:
        try:
            for minute in range(0, 60, 10):
                zipname = "INCA_GUST_" + str(minute).zfill(2) + ".asc"
                y = f.read(zipname)
                y = np.fromstring(y, sep=" ")
                if "x" not in locals():
                    x = y
                else:
                    x = np.maximum(x, y)
        except KeyError:
            try:
                try:
                    for minute in range(0, 60, 10):
                        zipname = (
                            "laefinca/inca/arc/gust/"
                            + str(dt.year)
                            + dt.strftime("%m")
                            + dt.strftime("%d")
                            + "/INCA_GUST_"
                            + str(minute).zfill(2)
                            + ".asc"
                        )
                        y = f.read(zipname)
                        y = np.fromstring(y, sep=" ")
                        if "x" not in locals():
                            x = y
                        else:
                            x = np.maximum(x, y)
                except KeyError:
                    list_min = [10, 20, 30, 50]
                    for minute in list_min:
                        zipname = "INCA_GUST_" + str(minute).zfill(2) + ".asc"
                        y = f.read(zipname)
                        y = np.fromstring(y, sep=" ")
                        if "x" not in locals():
                            x = y
                        else:
                            x = np.maximum(x, y)
            except KeyError:
                for minute in range(0, 60, 10):
                    zipname = (
                        "INCA_GUST_"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "_"
                        + str(dt.strftime("%H"))
                        + str(minute).zfill(2)
                        + ".asc"
                    )
                    y = f.read(zipname)
                    y = np.fromstring(y, sep=" ")
                    if "x" not in locals():
                        x = y
                    else:
                        x = np.maximum(x, y)

    else:
        x = f.read()
        x = np.fromstring(x, sep=" ")
        x[x < -90.0] = np.nan

    f.close()

    if twodim == True:
        if len(x) > 2 * nx * ny:
            content = x.reshape(33, ny, nx)
        else:
            try:
                content = x.reshape(ny, nx)
            except ValueError:
                content = np.ones((ny, nx)) * np.nan
    else:
        if len(x) > 2 * nx * ny:
            content = x.reshape(33, ny * nx)
        else:
            try:
                content = x.reshape(ny * nx)
            except ValueError:
                content = np.ones((ny, nx)) * np.nan

    if single_point is None:
        return content
    else:
        return content[:, single_point]


def INCA_to_netCDF(
    YYYYMMDDHH_begin,
    YYYYMMDDHH_end,
    dom,
    parameter,
    output_folder: str = "/cmod3/projects/climada/INCA_testcases/",
    *args
):
    """
    dom = 'AT':
        Windanalysen (Mittelwind) ab 01.01.2003 bis 01.06.2015, Boeen ab 01.05.2008 bis 01.06.2015
        Niederschlag 15-minuetig ab 01.01.2003
        Temperatur stuendlich ab 01.01.2003

    dom = 'L':
        Windanalysen (Mittelwind) ab 15.03.2011 bis aktuell, Boeen ab 18.03.2011 bis aktuell
        Niederschlag 1-stuendig ab 01.03.2012, 15-minuetig ab 10.09.2011
        Temperatur stuendlich ab 15.03.2011

    Parameters
    ----------
    content : YYYYMMDD - string
        specific day.
    dom : TYPE, optional
        domain investigated. Can be 'AT' or 'L'. The default is 'AT'.If the time range is later than 2015, there is automatically a change to domain 'L'.
    output_folder: string
        folder where to save the resulting netcdf file

    Returns
    -------
    xarray Dataset with the parameters precipitation (prec), temperature (temp), wind (uu/vv) and gusts (gust).

    """

    import numpy as np
    import xarray as xr

    # import plotting as pl #not used
    import pandas as pd
    import matplotlib.pyplot as plt
    from datetime import timedelta

    date_begin = pd.to_datetime(YYYYMMDDHH_begin, format="%Y%m%d%H", errors="ignore")
    date_end = pd.to_datetime(YYYYMMDDHH_end, format="%Y%m%d%H", errors="ignore")
    helpie = pd.date_range(start=date_begin, end=date_end, freq="H")
    timedelta_index = helpie.to_series()
    if date_begin.year >= 2015:
        print("Switch to large domain")
        dom = "L"

    # if date_begin.year <= '2011':
    #    dom = 'AT'

    if parameter == "prec":
        var = "RR"
    if parameter == "temp":
        var = "T2M"
    if parameter == "gust":
        var = "GUST"
    if parameter == "wind":
        var1 = "UU"
        var2 = "VV"
    if parameter == "relative_humidity":
        var = "RH2M"
    if parameter == "mslp":
        var = "P0"

    if dom == "AT":
        # Dimensionen f�r das Gitter auf dem die Parameter als netCDF gespeichert werden!
        nx = np.arange(100000, 700000 + 601000.0 / 601, 601000.0 / 601)
        ny = np.arange(250000, 600000 + 351000.0 / 351, 351000.0 / 351)
        time = len(timedelta_index)
        # data = np.zeros((len(ny), len(nx), time))
        DataSet = xr.Dataset(coords={"y": ny, "x": nx, "time": helpie})
        print(DataSet)  # das stimmt einmal

        # bei niederschlag noch summe bilden der vorherigen stunde
        DataSetList = []
        for index, value in timedelta_index.iteritems():
            dt = index.to_pydatetime()
            print(type(dt))
            if parameter == "prec":
                dt1 = dt - timedelta(hours=1)
                print(dt1)
                try:
                    inca_parameter_01 = read_INCA_ascii(
                        "/laefinca/inca/arc/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "15.asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    inca_parameter_02 = read_INCA_ascii(
                        "/laefinca/inca/arc/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "30.asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    inca_parameter_03 = read_INCA_ascii(
                        "/laefinca/inca/arc/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "45.asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    inca_parameter_04 = read_INCA_ascii(
                        "/laefinca/inca/arc/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt.strftime("%H")
                        + "00.asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    inca_parameter = (
                        inca_parameter_01
                        + inca_parameter_02
                        + inca_parameter_03
                        + inca_parameter_04
                    )
                except TypeError:
                    pass
            elif parameter == "gust":
                try:
                    print(dt.strftime("%H"))
                    inca_parameter = read_INCA_ascii(
                        "/laefinca/inca/arc/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_"
                        + var
                        + "_"
                        + dt.strftime("%H")
                        + ".zip",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                except ValueError:
                    inca_parameter = np.ones((len(ny), len(x))) * np.nan

            elif parameter == "wind":
                try:
                    inca_uu = read_INCA_ascii(
                        "/laefinca/inca/arc/wind/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_UU-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    inca_vv = read_INCA_ascii(
                        "/laefinca/inca/arc/wind/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_VV-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    inca_parameter = np.sqrt(inca_uu**2 + inca_vv**2)

                except (TypeError, ValueError):
                    inca_parameter = np.ones((len(ny), len(x))) * np.nan

            else:
                inca_parameter = read_INCA_ascii(
                    "/laefinca/inca/arc/"
                    + parameter
                    + "/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_"
                    + var
                    + "-"
                    + dt.strftime("%H")
                    + ".asc.gz",
                    dt,
                    dom="AT",
                    twodim=True,
                )

            DataSet_dt = DataSet.loc[dict(time=str(dt))]
            random_da = xr.DataArray(
                inca_parameter, dims=["y", "x"], coords={"x": nx, "y": ny}
            )
            DataSet_dt[parameter] = random_da

            for arg in args:
                if arg == "prec":
                    dt1 = dt - timedelta(hours=1)
                    inca_prec_01 = read_INCA_ascii(
                        "/laefinca/inca/arc/prec/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "15.asc.gz",
                        dt,
                        dom="AT",
                        twodim="True",
                    )
                    inca_prec_02 = read_INCA_ascii(
                        "/laefinca/inca/arc/prec/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "30.asc.gz",
                        dt,
                        dom="AT",
                        twodim="True",
                    )
                    inca_prec_03 = read_INCA_ascii(
                        "/laefinca/inca/arc/prec/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "45.asc.gz",
                        dt,
                        dom="AT",
                        twodim="True",
                    )
                    inca_prec_04 = read_INCA_ascii(
                        "/laefinca/inca/arc/prec/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt.strftime("%H")
                        + "00.asc.gz",
                        dt,
                        dom="AT",
                        twodim="True",
                    )
                    inca_prec = (
                        inca_prec_01 + inca_prec_02 + inca_prec_03 + inca_prec_04
                    )
                    random_prec = xr.DataArray(
                        inca_prec, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["prec"] = random_prec

                if arg == "temp":
                    inca_temp = read_INCA_ascii(
                        "/laefinca/inca/arc/temp/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_T2M-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    random_temp = xr.DataArray(
                        inca_temp, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["temp"] = random_temp

                if arg == "gust":
                    inca_gust = read_INCA_ascii(
                        "/laefinca/inca/arc/gust/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_GUST_"
                        + dt.strftime("%H")
                        + ".zip",
                        dt,
                        dom="AT",
                        twodim=True,
                    )
                    random_gust = xr.DataArray(
                        inca_gust, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    print(random_gust)
                    DataSet_dt["gust"] = random_gust

                if arg == "wind":
                    try:
                        inca_uu = read_INCA_ascii(
                            "/laefinca/inca/arc/wind/"
                            + str(dt.year)
                            + dt.strftime("%m")
                            + dt.strftime("%d")
                            + "/INCA_UU-"
                            + dt.strftime("%H")
                            + ".asc.gz",
                            dt,
                            dom="AT",
                            twodim=True,
                        )
                        inca_vv = read_INCA_ascii(
                            "/laefinca/inca/arc/wind/"
                            + str(dt.year)
                            + dt.strftime("%m")
                            + dt.strftime("%d")
                            + "/INCA_VV-"
                            + dt.strftime("%H")
                            + ".asc.gz",
                            dt,
                            dom="AT",
                            twodim=True,
                        )
                        inca_wind = np.sqrt(inca_uu**2 + inca_vv**2)
                        random_wind = xr.DataArray(
                            inca_wind, dims=["y", "x"], coords={"x": nx, "y": ny}
                        )

                    except (TypeError, ValueError):
                        random_wind = xr.DataArray(
                            np.ones((len(ny), len(nx))) * np.nan,
                            dims=["y", "x"],
                            coords={"x": nx, "y": ny},
                        )
                    DataSet_dt["wind"] = random_wind

            DataSetList.append(DataSet_dt)
        DataSet = xr.concat((DataSetList), dim="time")
        if "temp" in DataSet:
            DataSet["temp"].name = "Teperature 2 m"
            DataSet["temp"].attrs["units"] = "degree_Celsius"
            DataSet["temp"].attrs["short_name"] = "T2M"
            DataSet["temp"].attrs["long_name"] = "Air temperature in 2 m height"
        if "prec" in DataSet:
            DataSet["prec"].name = "Precipitation totals"
            DataSet["prec"].attrs["units"] = "mm"
            DataSet["prec"].attrs["short_name"] = "PREC"
            DataSet["prec"].attrs["long_name"] = "Hourly precipitation sum"

        if "wind" in DataSet:
            DataSet["wind"].name = "Wind speed"
            DataSet["wind"].attrs["units"] = "m/s"
            DataSet["wind"].attrs["short_name"] = "WIND"
            DataSet["wind"].attrs["long_name"] = "Mean Wind Speed in the last 10 min"

        if "gust" in DataSet:
            DataSet["gust"].name = "wind gusts"
            DataSet["gust"].attrs["units"] = "m/s"
            DataSet["gust"].attrs["short_name"] = "GUST"
            DataSet["gust"].attrs["long_name"] = "Maximum wind speed in the last 10 min"

        DataSet.attrs["title"] = "INCA - Domain: Austria"
        DataSet["time"].attrs["long_name"] = "time"
        DataSet["x"].attrs["units"] = "m"
        DataSet["x"].attrs["standard_name"] = "projection_x_coordinate"
        DataSet["x"].attrs["long_name"] = "x coordinate of projection"
        DataSet["y"].attrs["units"] = "m"
        DataSet["y"].attrs["standard_name"] = "projection_y_coordinate"
        DataSet["y"].attrs["long_name"] = "y coordinate of projection"
        DataSet.attrs[
            "institution"
        ] = "ZAMG - Zentralanstalt fuer Meteorologie und Geodynamik, Vienna, Austria"
        DataSet.attrs[
            "source"
        ] = "NetCDF version of INCA ascii files provided by Martin Kulmer (ZAMG)"
        DataSet.attrs[
            "references"
        ] = "https://www.zamg.ac.at/cms/de/forschung/wetter/inca"
        DataSet.attrs["projection"] = "MGI/ Austria Lambert - EPSG:31287"
        DataSet.attrs["contact"] = "Katharina Enigl (katharina.enigl@zamg.ac.at)"
        DataSet.attrs["Conventions"] = "CF-1.7"

    if dom == "L":
        # Dimensionen für das gitter, auf dem die Parameter als netCDF gespeichert werden!
        nx = np.arange(20000, 720000 + 701000.0 / 701, 701000.0 / 701)
        ny = np.arange(220000, 620000 + 401000.0 / 401, 401000.0 / 401)

        time = len(timedelta_index)
        # data = np.zeros((len(ny), len(nx), time))
        DataSet = xr.Dataset(coords={"y": ny, "x": nx, "time": helpie})

        DataSetList = []
        for index, value in timedelta_index.iteritems():
            dt = index.to_pydatetime()
            if parameter == "prec":
                dt1 = dt - timedelta(hours=1)
                inca_parameter_01 = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/"
                    + parameter
                    + "/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_RR-"
                    + dt1.strftime("%H")
                    + "15.asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )
                inca_parameter_02 = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/"
                    + parameter
                    + "/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_RR-"
                    + dt1.strftime("%H")
                    + "30.asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )
                inca_parameter_03 = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/"
                    + parameter
                    + "/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_RR-"
                    + dt1.strftime("%H")
                    + "45.asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )
                inca_parameter_04 = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/"
                    + parameter
                    + "/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_RR-"
                    + dt.strftime("%H")
                    + "00.asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )
                inca_parameter = (
                    inca_parameter_01
                    + inca_parameter_02
                    + inca_parameter_03
                    + inca_parameter_04
                )

            elif parameter == "gust":
                try:
                    inca_parameter = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_"
                        + var
                        + "_"
                        + dt.strftime("%H")
                        + ".zip",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                except ValueError:
                    inca_parameter = np.ones((len(ny), len(nx))) * np.nan

            elif parameter == "wind":
                try:
                    inca_uu = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/wind/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_UU-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_vv = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/wind/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_VV-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_parameter = np.sqrt(inca_uu**2 + inca_vv**2)
                except ValueError:
                    inca_parameter = np.ones((len(ny), len(nx))) * np.nan

            elif parameter == "relative_humidity":
                inca_parameter = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/temp/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_RH2M-"
                    + dt.strftime("%H")
                    + ".asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )
            elif parameter == "mslp":
                inca_parameter = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/mslp/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_P0_"
                    + dt.strftime("%H")
                    + ".asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )

            else:
                inca_parameter = read_INCA_ascii(
                    "/mapp_arch/mgruppe/arc/inca_l/"
                    + parameter
                    + "/"
                    + str(dt.year)
                    + dt.strftime("%m")
                    + dt.strftime("%d")
                    + "/INCA_"
                    + var
                    + "-"
                    + dt.strftime("%H")
                    + ".asc.gz",
                    dt,
                    dom="L",
                    twodim=True,
                )

            DataSet_dt = DataSet.loc[dict(time=str(dt))]
            random_da = xr.DataArray(
                inca_parameter, dims=["y", "x"], coords={"x": nx, "y": ny}
            )
            DataSet_dt[parameter] = random_da

            for arg in args:
                if arg == "prec":
                    inca_parameter_01 = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "15.asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_parameter_02 = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "30.asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_parameter_03 = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt1.strftime("%H")
                        + "45.asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_parameter_04 = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/"
                        + parameter
                        + "/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RR-"
                        + dt.strftime("%H")
                        + "00.asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_prec = (
                        inca_parameter_01
                        + inca_parameter_02
                        + inca_parameter_03
                        + inca_parameter_04
                    )
                    random_prec = xr.DataArray(
                        inca_prec, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["prec"] = random_prec

                if arg == "temp":
                    inca_temp = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/temp/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_T2M-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    random_temp = xr.DataArray(
                        inca_temp, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["temp"] = random_temp

                if arg == "relative_humidity":
                    inca_relhum = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/temp/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_RH2M-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    random_relhum = xr.DataArray(
                        inca_relhum, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["RH"] = random_temp

                if arg == "mslp":
                    inca_mslp = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/mlsp/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_P0_"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    random_mslp = xr.DataArray(
                        inca_mslp, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["mslp"] = random_temp

                if arg == "gust":
                    inca_gust = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/gust/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_GUST_"
                        + dt.strftime("%H")
                        + ".zip",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    random_gust = xr.DataArray(
                        inca_gust, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["gust"] = random_gust

                if arg == "wind":
                    inca_uu = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/wind/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_UU-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_vv = read_INCA_ascii(
                        "/mapp_arch/mgruppe/arc/inca_l/wind/"
                        + str(dt.year)
                        + dt.strftime("%m")
                        + dt.strftime("%d")
                        + "/INCA_VV-"
                        + dt.strftime("%H")
                        + ".asc.gz",
                        dt,
                        dom="L",
                        twodim=True,
                    )
                    inca_wind = np.sqrt(inca_uu**2 + inca_vv**2)
                    random_wind = xr.DataArray(
                        inca_wind, dims=["y", "x"], coords={"x": nx, "y": ny}
                    )
                    DataSet_dt["wind"] = random_wind

            DataSetList.append(DataSet_dt)

        DataSet = xr.concat((DataSetList), dim="time")
        if "temp" in DataSet:
            DataSet["temp"].name = "Teperature 2 m"
            DataSet["temp"].attrs["units"] = "degree_Celsius"
            DataSet["temp"].attrs["short_name"] = "T2M"
            DataSet["temp"].attrs["long_name"] = "Air temperature in 2 m height"
        if "prec" in DataSet:
            DataSet["prec"].name = "Precipitation totals"
            DataSet["prec"].attrs["units"] = "mm"
            DataSet["prec"].attrs["short_name"] = "PREC"
            DataSet["prec"].attrs["long_name"] = "Hourly precipitation sum"

        if "wind" in DataSet:
            DataSet["wind"].name = "Wind speed"
            DataSet["wind"].attrs["units"] = "m/s"
            DataSet["wind"].attrs["short_name"] = "WIND"
            DataSet["wind"].attrs["long_name"] = "Mean Wind in the last 10 min"

        if "gust" in DataSet:
            DataSet["gust"].name = "wind gusts"
            DataSet["gust"].attrs["units"] = "m/s"
            DataSet["gust"].attrs["short_name"] = "GUST"
            DataSet["gust"].attrs["long_name"] = "Maximum wind speed in the last 10 min"

        if "relative_humidity" in DataSet:
            DataSet["relative_humidity"].name = "relative_humidity"
            DataSet["relative_humidity"].attrs["units"] = "%"
            DataSet["relative_humidity"].attrs["short_name"] = "RH2M"
            DataSet["relative_humidity"].attrs[
                "long_name"
            ] = "Relative humidity in 2 m height"

        if "mslp" in DataSet:
            DataSet["mslp"].name = "surface_air_pressure"
            DataSet["mslp"].attrs["units"] = "Pa"
            DataSet["mslp"].attrs["short_name"] = "P0"
            DataSet["mslp"].attrs["long_name"] = "Mean surface level pressure"

        DataSet.attrs["title"] = "INCA - Domain: Austria"
        DataSet["time"].attrs["long_name"] = "time"
        DataSet["x"].attrs["units"] = "m"
        DataSet["x"].attrs["standard_name"] = "projection_x_coordinate"
        DataSet["x"].attrs["long_name"] = "x coordinate of projection"
        DataSet["y"].attrs["units"] = "m"
        DataSet["y"].attrs["standard_name"] = "projection_y_coordinate"
        DataSet["y"].attrs["long_name"] = "y coordinate of projection"
        DataSet.attrs[
            "institution"
        ] = "ZAMG - Zentralanstalt fuer Meteorologie und Geodynamik, Vienna, Austria"
        DataSet.attrs[
            "source"
        ] = "NetCDF version of INCA ascii files provided by Martin Kulmer (ZAMG)"
        DataSet.attrs[
            "references"
        ] = "https://www.zamg.ac.at/cms/de/forschung/wetter/inca"
        DataSet.attrs["projection"] = "MGI/ Austria Lambert - EPSG:31287"
        DataSet.attrs["contact"] = "Katharina Enigl (katharina.enigl@zamg.ac.at)"
        DataSet.attrs["Conventions"] = "CF-1.7"
        print(DataSet)

    # pl.plot_INCA(DataSet, YYYYMMDDHH_begin, YYYYMMDDHH_end, subplots = True)

    encoding = {
        parameter: {
            "dtype": "int16",
            "scale_factor": 0.1,
            "_FillValue": -9999,
            "zlib": True,
            "complevel": 9,
        }
    }

    return DataSet
