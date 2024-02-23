print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("readr")
  library("dplyr")
  library("sf")
  library("qs")
  library("glue")
  library("tictoc")
})

source("dev/utils.R")

ncores <- 32L

# x = read_sf("Rutschungen_gesamt.shp") # Masterarbeit
# y = read_sf("Rutschungsflaechen.shp") # KAGIS
# max(st_area(x))                           # 2794285 [m^2]
# quantile(st_area(x), 0.99)                #  426832 [m^2]
# quantile(st_area(y), 0.99)                #   35301 [m^2]
# max(st_area(y))                           #  101170 [m^2]
# quantile(c(st_area(x), st_area(y)), 0.99) #  288733 [m^2]
# sqrt(288733 / pi) = 303

wall("{Sys.time()} -- reading inventory")
inv <- read_sf("dat/reporting/inventar_kaernten.gpkg") |>
  mutate(slide = TRUE) |>
  select(slide, geom) |>
  st_transform(3416) |>
  st_buffer(units::as_units(300, "m")) |>
  st_union()
st_write(inv, "dat/interim/inventory/inv_buffered.gpkg", append = FALSE)

wall("{Sys.time()} -- reading AOI")
aoi <- read_sf("dat/raw/aoi/gaia_aoi_ktn_3416.gpkg") |>
  st_transform(3416)

wall("{Sys.time()} -- reading lakes")
lakes <- read_sf("dat/raw/water_bodies/OWK_SG.gpkg") |>
  st_transform(3416) |>
  select(See) |>
  st_intersection(aoi)
lakes |>
  mutate(area = st_area(geom)) |>
  st_drop_geometry()

wall("{Sys.time()} -- reading lithology")
litho_class <- read_tsv("doc/data_description/reclass_geology.tsv") |>
  select(-lithologie)
litho <- read_sf("dat/raw/geology/200k/Geologie_Kaernten_200.000.gpkg") |>
  st_transform(3416) |>
  select(leg_litho, geom) |>
  left_join(litho_class, by = "leg_litho") |>
  filter(class == 0) |>
  select(-class)
litho |>
  mutate(area = st_area(geom)) |>
  group_by(leg_litho) |>
  summarize(area = sum(area)) |>
  st_drop_geometry()
read_csv("doc/data_description/lut_lithology_200k_raw.csv") |>
  filter(leg_litho %in% c(2, 3, 15, 104, 930, 931))

wall("{Sys.time()} -- cutting holes")
absence_area <- st_difference(aoi, inv) |>
  st_difference(st_union(litho)) |>
  mutate(neg_sample = TRUE)

wall("{Sys.time()} -- saving absence area")
if (!file.exists("dat/interim/aoi/absence_area.gpkg")) {
  st_write(absence_area, "dat/interim/aoi/absence_area.gpkg")
}

wall("{Sys.time()} -- reading target grid")
grd <- qread("dat/interim/aoi/gaia_ktn_grid.qs", nthreads = ncores)

wall("{Sys.time()} -- performing spatial join") # 550 sec
tic()
absence_grid <- st_join(grd, absence_area, join = st_intersects, left = TRUE) |>
  select(-idx) |>
  sfc_as_cols() |>
  st_drop_geometry() |>
  mutate(neg_sample = tidyr::replace_na(neg_sample, FALSE)) |>
  select(neg_sample, x, y)
toc()

stopifnot(nrow(absence_grid) == nrow(grd))

wall("{Sys.time()} -- saving result")
qsave(absence_grid, "dat/interim/aoi/gaia_ktn_absence_grid.qs", nthreads = ncores)
wall("{Sys.time()} -- DONE")

# check
# tmp <- absence_grid |>
#   st_as_sf(coords = c("x", "y"), crs = 3416)
# tmp |>
#   filter(neg_sample == FALSE) |>
#   st_write("nosample_grd.gpkg")
# tmp |>
#   filter(neg_sample == TRUE) |>
#   st_write("sample_grd.gpkg")
