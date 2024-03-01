# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# plot spatial folds for all iterations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

suppressPackageStartupMessages({
  library("dplyr")
  library("sf")
  library("ggplot2")
  library("ggspatial")
  library("qs")
  library("glue")
  library("showtext")
})

source("dev/utils.R")

ncores <- 32L

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

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
  # scale_color_manual(values = unname(okabe_ito[c("darkorange", "darkblue", "green", "yellow", "pink")])) +
  annotation_north_arrow(
    location = "tr", which_north = "true",
    style = north_arrow_fancy_orienteering(
      text_size = 40, text_family = "Source Sans Pro"
    )
  ) +
  annotation_scale(location = "bl", width_hint = 0.4, text_cex = 3, text_family = "Source Sans Pro") +
  xlab("Longitude") +
  ylab("Latitude") +
  ggtitle("Landslide Susceptibility Analysis, Carinthia",
    subtitle = "Spatial Cross-Validation: Folds"
  ) +
  theme_linedraw() +
  theme(
    panel.grid.major = element_line(
      color = gray(0.5),
      linetype = "dashed",
      linewidth = 0.5
    ),
    panel.background = element_rect(fill = "white"),
    legend.position = "bottom",
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 40
    )
  ) +
  guides(color = guide_legend(override.aes = list(size = 5))) +
  facet_wrap(~iter, ncol = 2)

ggsave(filename = "plt/spcv.png", plot = p, width = 400, height = 380, units = "mm")

wall("{Sys.time()} -- DONE")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
