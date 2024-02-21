print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("glue")
  library("qs")
  library("colorspace")
  library("showtext")
  library("GGally")
})

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.ttf")
showtext_auto()

corrs <- read_rds("dat/interim/correlations.rds") |>
  rename(correlation = corr)

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

ggsave("plt/correlation.png", p, width = 130, height = 120, units = "mm")
print(glue::glue("{Sys.time()} -- done"))

dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores)

tmp <- dat |>
  select(starts_with("sw_"))

ggpairs(tmp) +
  theme_linedraw()
