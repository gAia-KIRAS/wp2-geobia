library(tidyverse)
library(sf)
library(glue)
library(qs)
library(tictoc)

ncores <- 28L

fl <- list.files("wp2-geobia/dat/interim/dtm_aoi/tmp_qs", pattern = "*.qs", full.names = TRUE)

tic()
res <- qread(fl[1], nthreads = ncores) %>%
  select(`aspect-arctan2`)
toc()
n <- nrow(res)

for (f in fl[2:length(fl)]) {
  print(glue("{Sys.time()} » Working on {basename(f)}"))
  tmp <- f %>%
    qread(nthreads = ncores) %>%
    st_drop_geometry()
  if (nrow(tmp) == n) {
    res <- res %>%
      bind_cols(tmp)
  } else {
    warning(glue(">> Problem in {basename(f)}: nrow = {nrow(tmp)} <<"))
  }
}

rm(f, tmp)
gc()
#colnames(res)[9] <- "elevation"
qsave(res, "wp2-geobia/dat/interim/dtm_aoi/dtm_full.qs", nthreads = ncores) #IMPORTANT: do not have that output
