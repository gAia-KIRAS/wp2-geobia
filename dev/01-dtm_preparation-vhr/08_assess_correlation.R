library(stars)
library(parallel)
library(dplyr)
library(tidyr)

fl <- list.files(
  "dat/interim/dtm_derivates/ktn_Nockberge_Ost",
  pattern = "tif", full.names = TRUE
)

param <- gsub("(dat/interim/dtm_derivates/ktn_Nockberge_Ost/dtm_carinthia_Nockberge_Ost_)(.*)(.tif)", "\\2", fl)

dem_to_mat <- function(x) {
  tif <- read_stars(x, RasterIO = list(nBufXSize = 50, nBufYSize = 50, bands = 1), proxy = FALSE)
  res <- unclass(tif)[[1]]
  res <- as.vector(res)
  return(res)
}

tifs <- mclapply(fl, dem_to_mat, mc.cores = 12L)
names(tifs) <- param

dat <- tifs %>%
  bind_rows() %>%
  select(-`channel-network`, -`watershed-basins`) %>%
  drop_na()
