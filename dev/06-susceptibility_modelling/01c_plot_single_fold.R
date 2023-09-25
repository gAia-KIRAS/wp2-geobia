# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# plot spatial folds for all iterations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(ggplot2)
  library(ggspatial)
  library(colorspace)
  library(qs)
  library(glue)
  library(showtext)
})

source("dev/utils.R")

wall("{Sys.time()} -- reading data")

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

ncores <- 32L

aoi <- read_sf("dat/raw/aoi/gaia_projektgebiet_ktn.gpkg") |>
  st_transform(3416) |>
  st_union() |>
  nngeo::st_remove_holes()

dat <- qread("dat/processed/gaia_ktn_balanced_iters_spatialfolds.qs", nthreads = ncores) |>
  st_as_sf(coords = c("x", "y"), crs = 3416) |>
  mutate(iter = paste("iteration:", sprintf("%02d", iter))) |>
  filter(iter == "iteration: 01") |>
  select(slide, fold, geometry)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

p <- ggplot() +
  geom_sf(data = aoi, color = "black", fill = NA, linewidth = 1) +
  geom_sf(data = dat, aes(color = fold), alpha = 0.5, show.legend = FALSE) +
  geom_sf(
    data = dat |> filter(slide == "TRUE"),
    alpha = 0.5,
    shape = 21
  ) +
  scale_color_discrete_qualitative(palette = "dynamic") +
  annotation_north_arrow(
    location = "tr",
    which_north = "true",
    style = north_arrow_fancy_orienteering(
      text_family = "Source Sans Pro",
      text_size = 25
    )
  ) +
  annotation_scale(
    location = "bl", width_hint = 0.4,
    text_family = "Source Sans Pro", text_cex = 3
  ) +
  xlab("Longitude") +
  ylab("Latitude") +
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
      size = 30
    )
  )

ggsave(filename = "plt/spcv_outer_folds.png", plot = p, width = 300, height = 100, units = "mm", dpi = 300)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

dat_focus <- dat |>
  filter(fold == 2)

dat_holdout <- dat |>
  filter(fold != 2) |>
  sfc_as_cols()

p <- ggplot() +
  geom_sf(data = aoi, color = "black", fill = NA, linewidth = 1) +
  geom_sf(data = dat_focus, color = okabe_ito["darkorange"], alpha = 0.5) +
  geom_sf(data = dat_holdout, color = okabe_ito["darkblue"], alpha = 0.5) +
  geom_sf(
    data = dat |> filter(slide == "TRUE"),
    alpha = 0.5,
    shape = 23
  ) +
  scale_color_discrete_qualitative(palette = "dynamic") +
  annotation_north_arrow(
    location = "tr",
    which_north = "true",
    style = north_arrow_fancy_orienteering(
      text_family = "Source Sans Pro",
      text_size = 25
    )
  ) +
  annotation_scale(
    location = "bl", width_hint = 0.4,
    text_family = "Source Sans Pro", text_cex = 3
  ) +
  xlab("Longitude") +
  ylab("Latitude") +
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
      size = 30
    )
  )

ggsave(filename = "plt/spcv_outer_train_test.png", plot = p, width = 300, height = 100, units = "mm", dpi = 300)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

set.seed(1)
clust <- dat_holdout |>
  select(x, y) |>
  st_drop_geometry() |>
  kmeans(centers = 4)

dat_holdout <- dat_holdout |>
  mutate(cluster = as.factor(clust$cluster))

p <- ggplot() +
  geom_sf(data = aoi, color = "black", fill = NA, linewidth = 1) +
  geom_sf(data = dat_focus, color = "grey60", alpha = 0.5) +
  geom_sf(data = dat_holdout, aes(color = cluster), alpha = 0.5, show.legend = FALSE) +
  geom_sf(
    data = dat |> filter(slide == "TRUE"),
    alpha = 0.5,
    shape = 21
  ) +
  scale_color_discrete_qualitative(palette = "dynamic") +
  annotation_north_arrow(
    location = "tr",
    which_north = "true",
    style = north_arrow_fancy_orienteering(
      text_family = "Source Sans Pro",
      text_size = 25
    )
  ) +
  annotation_scale(
    location = "bl", width_hint = 0.4,
    text_family = "Source Sans Pro", text_cex = 3
  ) +
  xlab("Longitude") +
  ylab("Latitude") +
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
      size = 30
    )
  )

ggsave(filename = "plt/spcv_inner.png", plot = p, width = 300, height = 100, units = "mm", dpi = 300)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

p <- ggplot() +
  geom_sf(data = aoi, color = "black", fill = NA, linewidth = 1) +
  geom_sf(data = dat_focus, color = "grey60", alpha = 0.25) +
  geom_sf(data = dat_holdout |> filter(cluster == 2), color = okabe_ito["orange"], alpha = 0.5) +
  geom_sf(data = dat_holdout |> filter(cluster != 2), color = okabe_ito["skyblue"], alpha = 0.5) +
  geom_sf(
    data = dat |> filter(slide == "TRUE"),
    alpha = 0.5,
    shape = 21
  ) +
  annotation_north_arrow(
    location = "tr",
    which_north = "true",
    style = north_arrow_fancy_orienteering(
      text_family = "Source Sans Pro",
      text_size = 25
    )
  ) +
  annotation_scale(
    location = "bl", width_hint = 0.4,
    text_family = "Source Sans Pro", text_cex = 3
  ) +
  xlab("Longitude") +
  ylab("Latitude") +
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
      size = 30
    )
  )

ggsave(filename = "plt/spcv_inner_train_test.png", plot = p, width = 300, height = 100, units = "mm", dpi = 300)

wall("{Sys.time()} -- DONE")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
