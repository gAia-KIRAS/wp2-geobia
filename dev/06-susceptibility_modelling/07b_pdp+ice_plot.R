# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ALE plots
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("showtext")
  library("qs")
  library("glue")
})

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.ttf")
showtext_auto()

ncores <- 16L

glue("{Sys.time()} -- reading data")
dat <- qread("dat/interim/random_forest/pdp+ice.qs", nthreads = ncores)
features <- names(dat)
lut_names <- read_csv("doc/data_description/lut_vars.csv")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

export_plot <- function(feature, data = dat) {
  res <- data[[feature]]
  pdp <- res |>
    filter(.type == "pdp") |>
    select(iteration:.value)
  varname <- lut_names |>
    filter(feature_shortname == feature) |>
    pull(feature_name)
  p <- ggplot(res, aes(x = .data[[feature]], y = .value)) +
    geom_line(aes(group = .id), alpha = 0.1) +
    geom_line(data = pdp, color = "#E69F00", linewidth = 1) +
    facet_grid(iteration ~ .class) +
    theme_linedraw() +
    theme(
      text = element_text(
        family = "Source Sans Pro",
        colour = "black",
        size = 20
      ),
      legend.position = "right"
    ) +
    xlab(label = varname) +
    scale_y_continuous(name = "predicted landslide probatility", limits = c(0, 1))
  ggsave(glue("plt/pdp_ice_{feature}.png"), p, width = 120, height = 300, units = "mm")
}

export_plot("wei")
