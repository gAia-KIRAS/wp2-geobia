library(dplyr)
library(sf)
library(glue)
library(qs)

# grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 64L)
# n <- nrow(grd)
n <- 57842689

fl <- list.files("dat/interim/oberflaechenabfluss/prep", pattern = "*.qs", full.names = TRUE)

res <- qread(fl[1], nthreads = 64L)
nrow(res) == n

for (f in fl[2:length(fl)]) {
  print(glue("{Sys.time()} » Working on {basename(f)}"))
  tmp <- f |>
    qread(nthreads = 64L)
  if (nrow(tmp) == n) {
    print(glue(">> {basename(f)}: matching number of rows <<"))
    res <- res |>
      bind_cols(tmp |> st_drop_geometry())
  } else {
    print(glue(">> {basename(f)}: nrow = {nrow(tmp)} != {n} <<"))
    res <- res |>
      st_join(tmp)
  }
}

rm(f, tmp)
gc()
qsave(res, "dat/interim/misc_aoi/surface_water.qs", nthreads = 64L)
