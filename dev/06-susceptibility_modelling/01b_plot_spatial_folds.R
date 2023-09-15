# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# plot spatial folds for all iterations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(ggplot2)
  library(ggspatial)
  library(qs)
  library(glue)
})

source("dev/utils.R")

ncores <- 32L

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416) |>
  st_union() |>
  nngeo::st_remove_holes()

dat <- qread("dat/processed/gaia_ktn_balanced_iters_spatialfolds.qs", nthreads = ncores) |>
  st_as_sf(coords = c("x", "y"), crs = 3416) |>
  mutate(iter = paste("iteration:", sprintf("%02d", iter)))

p <- ggplot() +
  geom_sf(data = aoi, color = "black", fill = NA, linewidth = 2) +
  geom_sf(data = dat, aes(color = fold), alpha = 0.5) +
  geom_sf(
    data = dat |> filter(slide == "TRUE"),
    alpha = 0.5,
    shape = 23
  ) +
  annotation_north_arrow(
    location = "tr", which_north = "true",
    style = north_arrow_fancy_orienteering
  ) +
  annotation_scale(location = "bl", width_hint = 0.4) +
  xlab("Longitude") +
  ylab("Latitude") +
  ggtitle("Landslide Susceptibility Analysis, Carinthia",
    subtitle = "Spatial Cross-Validation: Folds"
  ) +
  theme(
    panel.grid.major = element_line(
      color = gray(0.5),
      linetype = "dashed",
      linewidth = 0.5
    ),
    panel.background = element_rect(fill = "white"),
    legend.position = "bottom"
  ) +
  facet_wrap(~iter, ncol = 2)

ggsave(filename = "plt/spcv.png", plot = p, width = 400, height = 380, units = "mm")

wall("{Sys.time()} -- DONE")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
