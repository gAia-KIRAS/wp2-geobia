print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(qs)
  library(arrow)
  library(sfarrow)
  library(glue)
})

source("dev/utils.R")

# expected number of pixels: 57,842,689

# terrain features
print(glue("{Sys.time()} -- reading terrain features"))

# land cover, forest cover
print(glue("{Sys.time()} -- reading land cover features"))
lc <- qread("dat/interim/misc_aoi/land_cover_full.qs", nthreads = ncores)
stopifnot(identical(st_coordinates(dtm), st_coordinates(lc)))

# climate indicators
print(glue("{Sys.time()} -- reading climate indicators"))
stopifnot(identical(st_coordinates(dtm), st_coordinates(ci)))

# surface water
print(glue("{Sys.time()} -- reading surface water features"))
stopifnot(identical(st_coordinates(dtm), st_coordinates(sw)))
# distance to roads
print(glue("{Sys.time()} -- reading distance to roads"))
rd <- qread("dat/interim/misc_aoi/road_dist.qs", nthreads = ncores) |>
  select(dist)
stopifnot(nrow(rd) == nrow(dtm))

# merge all data sets
print(glue("{Sys.time()} -- combining data sets"))
out <- dtm |>
  bind_cols(rd) |>

# save w/ simple feature geometry column (parquet)
print(glue("{Sys.time()} -- writing parquet"))
st_write_parquet(obj = out, dsn = "dat/processed/carinthia_10m.parquet")
print(glue("    object size w/ sf geom:"))
format(object.size(out), "auto")

# save w/o simple feature geometry (ipc / arrow)
print(glue("{Sys.time()} -- writing ipc"))
res <- out |>
  sfc_as_cols() |>
  st_drop_geometry()
write_ipc_file(res, sink = "dat/processed/carinthia_10m.arrow", compression = "lz4")
print(glue("    object size w/o sf geom:"))
format(object.size(res), "auto")

print(glue("{Sys.time()} -- DONE \\o/"))
