print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("glue")
  library("qs")
  library("colorspace")
  library("showtext")
  library("GGally")
})

source("dev/utils.R")

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores) |>
  select(
    -elevation, -maximum_height, -wei,
    -roughness, -tri, -svf,
    -flow_path_length, -flow_width, -sca,
    -api_k30, -rx5day,
    -forest_cover,
    -road_dist,
    -sw_hazard_cat, -sw_max_depth, -sw_max_speed,
    -esa
  ) |>
  mutate(across(everything(), as.numeric))

res <- dat |>
  filter(iter == 1 & slide == 1) |>
  bind_rows(filter(dat, slide == 0))

cn <- colnames(res)
corrs <- crossing(cn, cn)
corr <- map2_dbl(corrs$cn...1, corrs$cn...2, compute_corr, .progress = TRUE)
corrs$correlation <- corr

p <- ggplot(corrs, aes(x = cn...1, y = cn...2)) +
  geom_raster(aes(fill = correlation)) +
  xlab("") +
  ylab("") +
  scale_fill_continuous_diverging("Vik", limits = c(-1, 1)) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 20
    ),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
    legend.position = "right"
  )

ggsave("plt/correlation_tuning_sample.png", p, width = 130, height = 120, units = "mm")
print(glue::glue("{Sys.time()} -- done"))
