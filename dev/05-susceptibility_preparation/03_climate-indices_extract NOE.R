library(dplyr)
library(sf)
library(stars)
library(qs)
library(magrittr)
library(stars)

# AOI dataframe
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 64L)
aoi <- read_sf("wp2-geobia/dat/interim/aoi/NOE_gaiaArea.shp")  %>% # shp information of the region 
  st_transform(3416)

# climdex
i1d <- read_ncdf("wp2-geobia/dat/interim/weather_climate_grids/climdex_indices_mean_q95_noe.nc") %>% 
  st_set_crs(3416)
i1n <- st_get_dimension_values(i1d, "variable") %>%
  gsub("RRR", "R", .) %>%
  tolower()
i1e <- i1d %>%
  st_extract(grd) %>%
  st_as_sf(as_points = TRUE) %>%
  setNames(c(i1n, "geometry"))

# api, pci, spei
i2d <- read_ncdf("wp2-geobia/dat/interim/weather_climate_grids/api_spei_pci_indices_q95_mean_noe.nc") %>%
  st_set_crs(3416)
i2n <- st_get_dimension_values(i2d, "variable") %>%
  gsub("p0.935_", "", .) %>%
  gsub("_yearpctl95", "", .) |>
  tolower()
i2e <- i2d |>
  st_extract(grd) |>
  st_as_sf(as_points = TRUE) |>
  setNames(c(i2n, "geometry"))

nrow(i1e) == nrow(i2e)
identical(st_coordinates(i1e), st_coordinates(i2e))
res <- i1e |>
  bind_cols(i2e |> st_drop_geometry())
# res <- st_join(i1e, i2e)

qsave(res, "dat/interim/misc_aoi/climate_indices.qs", nthreads = 64L)
