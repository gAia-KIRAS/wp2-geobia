# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ALE plots
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("showtext")
  library("qs")
  library("glue")
  library("parallel")
})

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

ncores <- 16L

glue("{Sys.time()} -- reading data")
dat <- qread("dat/interim/random_forest/pdp+ice.qs", nthreads = ncores)
features <- names(dat)
lut_names <- read_csv("doc/lut/lut_vars.csv")

factors <- c("land_cover", "forest_cover", "geomorphons", "lithology")

lut_lc <- tribble(
  ~land_cover, ~lc,
  11, "Built-up",
  12, "Flat sealed surfaces",
  31, "Permanent soil",
  32, "Bare rock and screes",
  60, "Water",
  70, "Snow and ice",
  91, "Trees - broad leaved",
  93, "Trees - coniferous",
  100, "Bushes and shrubs",
  122, "Herbaceous periodically",
  124, "Herbaceous permanent",
  125, "Herbaceous permanent -\nlow productivity",
  126, "Herbaceous permanent -\nhigh productivity",
  130, "Reeds"
)

lut_geology <- read_csv("doc/lut/lut_lithology_200k_reclass_en.csv") |>
  mutate(name = gsub("^unconsolidated sediments ", "unconsolidated sediments\n", name))

lut_geomorphons <- read_csv("doc/lut/lut_geomorphons.csv")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

export_plot <- function(feature, data = dat) {
  res <- data[[feature]] |>
    filter(iteration == 1)
  if (feature == "land_cover") {
    res <- res |>
      mutate(land_cover = as.integer(as.character(land_cover))) |>
      left_join(lut_lc, by = join_by(land_cover)) |>
      select(iteration, land_cover = lc, .class, .value, .type)
  }
  if (feature == "lithology") {
    res <- res |>
      mutate(lithology = as.integer(as.character(lithology))) |>
      filter(lithology != 0) |>
      left_join(lut_geology, by = join_by(lithology == id)) |>
      select(iteration, lithology = name, .class, .value, .type)
  }
  if (feature == "geomorphons") {
    res <- res |>
      mutate(geomorphons = as.integer(as.character(geomorphons))) |>
      left_join(lut_geomorphons, by = join_by(geomorphons == id)) |>
      select(iteration, geomorphons = name, .class, .value, .type)
  }
  pdp <- res |>
    filter(.type == "pdp") |>
    select(iteration:.value)
  varname <- lut_names |>
    filter(feature_shortname == feature) |>
    pull(feature_name)
  if (feature %in% factors) {
    p <- ggplot(res, aes(x = .data[[feature]], y = .value)) +
      geom_boxplot() +
      geom_point(data = pdp, color = "#E69F00", size = 2)
  } else {
    p <- ggplot(res, aes(x = .data[[feature]], y = .value)) +
      geom_line(aes(group = .id), alpha = 0.1) +
      geom_line(data = pdp, color = "#E69F00", linewidth = 1)
  }
  p <- p +
    facet_wrap(~.class) +
    theme_linedraw() +
    theme(
      text = element_text(
        family = "Source Sans Pro",
        colour = "black",
        size = 40
      ),
      legend.position = "right"
    ) +
    xlab(label = varname) +
    scale_y_continuous(name = "predicted landslide probatility", limits = c(0, 1))
  if (feature %in% factors) {
    p <- p + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, lineheight = 0.5))
  }
  if (feature == "vrm") {
    p <- p + scale_x_log10()
  }
  if (feature == "tpi") {
    p <- p + coord_cartesian(xlim = c(-2.5, 2.5))
  }
  ggsave(glue("plt/pdp_ice_{feature}.png"), p, width = 240, height = 120, units = "mm")
}

glue("{Sys.time()} -- plotting")
mclapply(features, export_plot, mc.cores = ncores)
glue("{Sys.time()} -- DONE \\o/")
