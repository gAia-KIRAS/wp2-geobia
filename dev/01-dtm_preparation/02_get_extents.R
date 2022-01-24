# load packages
library("tidyverse")
library("sf")
library("raster")
library("parallel")

# capture tile name
capture_filename <- function(filelist, pattern) {
  lapply(filelist, function(x) gsub(pattern, "\\2", x)) %>%
    unlist() %>%
    enframe(name = "id", value = "tile")
}

# get extent from raster
get_extent <- function(ras) {
  tmp <- raster(ras)
  ext <- extent(tmp)
  return(ext)
}

# convert extent to sf
extent_to_sf <- function(extent) {
  out <- st_as_sf(as(extent, "SpatialPolygons"))
  st_crs(out) <- 31256
  return(out)
}

# create sf
sf_from_raster <- function(data_dir, file_ending, regex_pattern, resolution, ncores = 32L) {
  fl <- list.files(data_dir, pattern = file_ending, full.name = TRUE, ignore.case = TRUE)
  fn <- capture_filename(filelist = fl, pattern = regex_pattern)
  extent_list <- mclapply(fl, get_extent, mc.cores = ncores)
  extent_list_sf <- mclapply(extent_list, extent_to_sf, mc.cores = ncores)
  extents <- data.table::rbindlist(extent_list_sf) %>%
    st_as_sf() %>%
    bind_cols(fn) %>%
    dplyr::select(id, tile, geometry)
  return(extents)
}

extents <- sf_from_raster(
  data_dir = "dat/raw/dtm/dtm_noe/dtm_grd",
  file_ending = "*.grd$",
  regex_pattern = "(dat/raw/dtm/dtm_noe/dtm_grd/)(.*)(\\.[gG][rR][dD])"
)

# export result
st_write(extents, "dat/interim/dtm/extents_noe.gpkg")
write_rds(extents, "dat/interim/dtm/extents_noe.rds")
