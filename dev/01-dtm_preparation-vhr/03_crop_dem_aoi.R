# load packages
library("dplyr")
library("tibble")
library("sf")
library("stars")
library("glue")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# AOI for testing purposes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# create polygon somewhere in Oberkärnten
xmin <- 436350
xmax <- 439730
ymin <- 200200
ymax <- 202420

test_aoi <- c(
  xmin, xmax, xmax, xmin, xmin,
  ymin, ymin, ymax, ymax, ymin
) %>%
  matrix(ncol = 2) %>%
  list() %>%
  st_polygon() %>%
  st_sfc(crs = 31258)

# export result
st_write(test_aoi, "dat/interim/aoi/test_area.gpkg")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# AOI Carinthia
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# predefined AOI polygon
carinthia <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg")

# full dtm
dtm <- read_stars("dat/raw/dtm/dtm_ktn/ALS_DGM_1m.img")
st_crs(dtm) <- 31258

# crop to small aoi for testing purposes
dtm %>%
  st_crop(test_aoi) %>%
  write_stars("dat/interim/dtm/test_aoi_ktn.tif")

# crop to regions
for (region in carinthia$name) {
  print(glue("{Sys.time()} -- Working on region '{region}'"))
  outfile <- glue("dat/interim/dtm/dtm_carinthia_{region}.tif")
  tmp_aoi <- carinthia %>%
    filter(name == region)
  if (file.exists(outfile)) {
    cat("  » Area cropped already\n")
  } else {
    cat("  » Cropping\n")
    dtm %>%
      st_crop(tmp_aoi) %>%
      write_stars(outfile)
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# AOI Lower Austria
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

noe_tiles <- read_sf("dat/interim/dtm/extents_noe.gpkg")
noe_aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_noe/NOE_gaiaArea.shp") %>%
  st_transform(31256)

noe <- st_join(noe_aoi, noe_tiles) %>%
  remove_rownames() %>%
  mutate(f_pth = glue("dat/raw/dtm/dtm_noe/dtm_grd/{tile}.grd")) %>%
  mutate(f_pth = if_else(file.exists(f_pth), f_pth, glue("dat/raw/dtm/dtm_noe/dtm_grd/{tile}.GRD")))

table(file.exists(noe$f_pth))

fls <- noe %>%
  st_drop_geometry() %>%
  select(Name, f_pth) %>%
  group_by(Name)

for (name in unique(fls$Name)) {
  print(glue("{Sys.time()} -- Working on {name}"))
  ifl <- glue("dat/interim/dtm/noe_{name}_list.txt")
  ofl <- glue("dat/interim/dtm/dtm_noe_{name}")
  try(unlink(ifl))
  fls %>%
    filter(Name == name) %>%
    pull(f_pth) %>%
    writeLines(ifl)
  print(glue("{Sys.time()} -- Build VRT"))
  cmd1 <- glue("gdalbuildvrt -input_file_list {ifl} -overwrite {ofl}.vrt")
  system(cmd1, intern = TRUE, ignore.stderr = TRUE)
  print(glue("{Sys.time()} -- Translate to GeoTIFF"))
  cmd2 <- glue("gdal_translate {ofl}.vrt {ofl}.tif")
  system(cmd2, intern = TRUE, ignore.stderr = TRUE)
  print(glue("{Sys.time()} -- {name} done"))
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# gdalwarp -dstnodata -9999 -cutline dat/interim/aoi/test_area.gpkg dat/raw/dtm/dtm_ktn/ALS_DGM_1m.img dat/interim/dtm/test_aoi_ktn.tif
