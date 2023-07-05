library(dplyr)
library(sf)
library(stars)
library(qs)

# AOI dataframe
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 64L)

# climdex
i1d <- read_ncdf("dat/interim/weather_climate_grids/climdex_indices_mean_q95.nc") |>
  st_set_crs(3416)
i1n <- st_get_dimension_values(i1d, "variable") %>%
  gsub("RRR", "R", .) |>
  tolower()
i1e <- i1d |>
  st_extract(grd) |>
  st_as_sf(as_points = TRUE) |>
  setNames(c(i1n, "geometry"))

# api, pci, spei
i2d <- read_ncdf("dat/interim/weather_climate_grids/api_spei_pci_indices_q95_mean.nc") |>
  st_set_crs(3416)
i2n <- st_get_dimension_values(i2d, "variable") %>%
  gsub("p0.935_", "", .) %>%
  gsub("_yearpctl95", "", .) |>
  tolower()
i2e <- i2d |>
  st_extract(grd) |>
  st_as_sf(as_points = TRUE) |>
  setNames(c(i2n, "geometry"))

res <- st_join(i1e, i2e)
qsave(res, "dat/interim/misc_aoi/climate_indices.qs", nthreads = 64L)
