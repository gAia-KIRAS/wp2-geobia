import xarray as xr
from inca import INCA_to_netCDF

for param in ['relative_humidity', 'prec', 'wind', 'gust', 'mslp', ]: #'prec', 'wind', 'gust', 'mslp', 
    inca_test = INCA_to_netCDF(2018070100, 2018123123, 'L', param,'/cmod3/projects/gaia/')