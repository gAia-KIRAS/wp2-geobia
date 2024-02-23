print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("glue")
  library("qs")
  library("colorspace")
  library("showtext")
  library("GGally")
})

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

fullnames <- read_csv("doc/data_description/lut_vars.csv") |>
  select(-progenitor) |>
  mutate(feature_name = gsub(
    pattern = "30-day standardized precipitation evapotranspiration index",
    replacement = "30-day SPEI",
    x = feature_name
  ))

corrs <- read_rds("dat/interim/correlations.rds") |>
  left_join(fullnames, by = join_by("cn...1" == "feature_shortname")) |>
  rename(feature_1 = feature_name) |>
  left_join(fullnames, by = join_by("cn...2" == "feature_shortname")) |>
  rename(feature_2 = feature_name)

p <- ggplot(corrs, aes(x = feature_1, y = feature_2)) +
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
