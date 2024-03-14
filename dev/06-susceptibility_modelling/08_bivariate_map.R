library("sf")
library("stars")
library("dplyr")
library("ggplot2")
library("patchwork")
library("biscale")

# xmin <- 432500
# xmax <- 435500
# ymin <- 318500
# ymax <- 322500

# height <- 100
# width <- ceiling(height * (xmax - xmin) / (ymax - ymin))

# aoi <- st_sfc(st_polygon(list(cbind(c(xmin, xmax, xmax, xmin, xmin), c(ymin, ymin, ymax, ymax, ymin)))), crs = 3416)
# res <- qs::qread("dat/processed/prediction/random_forest_prediction_mean_sd_sf.qs", nthreads = 16L) |>
#   st_intersection(aoi)
# saveRDS(res, "dat/processed/prediction/biscale_test_aoi.rds")

# pals = c("Bluegill", "BlueGold", "BlueOr", "BlueYl", "Brown", "DkBlue", "DkCyan", "DkViolet", "GrPink", "PinkGrn", "PurpleGrn", "PurpleOr")
pals <- c("Brown", "PurpleOr", "GrPink", "DkViolet")
pal <- pals[2]
dims <- 3
p_pals <- lapply(pals, bi_pal, dim = dims)
wrap_plots(p_pals)

res <- readRDS("dat/processed/prediction/biscale_test_aoi.rds") |>
  st_intersection(aoi) |>
  rename(susceptibility = mean_susc, uncertainty = sd_susc) |>
  st_rasterize() |>
  st_as_sf() |>
  bi_class(x = susceptibility, y = uncertainty, style = "quantile", dim = dims)

map <- ggplot() +
  geom_sf(data = res, mapping = aes(fill = bi_class, color = bi_class), show.legend = FALSE) +
  bi_scale_fill(pal = pal, dim = dims) +
  bi_scale_color(pal = pal, dim = dims) +
  theme_linedraw()

legend <- bi_legend(
  pal = pal,
  dim = dims,
  xlab = "susceptibility",
  ylab = "uncertainty",
  size = 8
)

p <- map + legend + plot_layout(widths = c(6, 2))

ggsave(filename = "plt/test_map.png", plot = p, width = 130, height = 100, units = "mm")
