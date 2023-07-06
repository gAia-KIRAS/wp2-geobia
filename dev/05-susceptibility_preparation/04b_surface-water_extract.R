library(dplyr)
library(sf)
library(stars)
library(glue)
library(qs)

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416)
# grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 64L)

fl <- list.files("dat/interim/oberflaechenabfluss/prep", pattern = ".tif$", full.names = TRUE)

tif_to_qs <- function(raster, crop = aoi) {
  outfile <- gsub("tif", "qs", raster)
  if (file.exists(outfile)) {
    print(glue("{Sys.time()} -- Skipping {basename(outfile)} (file exists)"))
  } else {
    print(glue("{Sys.time()} -- Working on {basename(raster)}"))
    varname <- gsub("^(KTN_)(.*)(.tif)", "\\2", basename(raster))
    print(glue("{Sys.time()} --   Crop"))
    res <- read_stars(raster) |>
      st_crop(crop) |>
      st_as_sf(as_points = TRUE)
    colnames(res)[1] <- varname
    print(glue("{Sys.time()} --   Save"))
    qsave(res, outfile, nthreads = 64L)
  }
}

lapply(fl, tif_to_qs)

# unclipped: 107085888
# target: 57842689
