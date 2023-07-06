library(dplyr)
library(sf)
library(glue)
library(qs)

grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = 64L)
n <- nrow(grd)

fl <- list.files("dat/interim/oberflaechenabfluss/prep", pattern = "*.qs", full.names = TRUE)

res <- qread(fl[1], nthreads = 64L)
nrow(res) == n

for (f in fl[2:length(fl)]) {
  print(glue("{Sys.time()} » Working on {basename(f)}"))
  tmp <- f |>
    qread(nthreads = 64L) |>
    st_drop_geometry()
  if (nrow(tmp) == n) {
    res <- res |>
      bind_cols(tmp)
  } else {
    warning(glue(">> Problem in {basename(f)}: nrow = {nrow(tmp)} <<"))
  }
}

rm(f, tmp)
gc()
qsave(res, "dat/interim/misc_aoi/surface_water.qs", nthreads = 64L)

# unclipped: 107085888
# target: 57842689
