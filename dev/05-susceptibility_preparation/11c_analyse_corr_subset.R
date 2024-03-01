print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("glue")
  library("qs")
  library("colorspace")
  library("showtext")
  library("GGally")
})

ncores <- 16L

# specify plot type: full (all features) vs reduced (selected features)
# type <- "full"
type <- "reduced"

source("dev/utils.R")

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

fullnames <- read_csv("doc/data_description/lut_vars.csv") |>
  select(-progenitor) |>
  mutate(feature_name = gsub(
    pattern = "30-day standardized precipitation evapotranspiration index",
    replacement = "30-day SPEI",
    x = feature_name
  ))

dat <- qread("dat/processed/gaia_ktn_balanced_iters.qs", nthreads = ncores) |>
  mutate(across(everything(), as.numeric))

if (type == "reduced") {
  dat <- dat |>
    select(
      -elevation, -maximum_height, -wei,
      -roughness, -tri, -svf,
      -pto, -nto, -curv_max, -curv_min, -dah,
      -flow_path_length, -flow_width, -sca,
      -api_k7, -api_k30, -rx1day, -rx5day, -sdii,
      -forest_cover,
      -road_dist,
      -sw_hazard_cat, -sw_max_depth, -sw_max_speed,
      -esa, -x, -y
    )
}

res <- dat |>
  filter(iter == 1 & slide == 1) |>
  bind_rows(filter(dat, slide == 0)) |>
  select(-iter)

cn <- colnames(res)
corrs <- crossing(cn, cn)
corr <- map2_dbl(corrs$cn...1, corrs$cn...2, compute_corr, .progress = TRUE)

corrs <- corrs |>
  mutate(correlation = corr) |>
  left_join(fullnames, by = join_by("cn...1" == "feature_shortname")) |>
  rename(feature_1 = feature_name) |>
  left_join(fullnames, by = join_by("cn...2" == "feature_shortname")) |>
  rename(feature_2 = feature_name)

corrs |>
  filter(correlation < 1) |>
  mutate(corr_abs = abs(correlation)) |>
  arrange(-corr_abs)

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

ggsave(glue("plt/correlation_tuning_{type}.png"), p, width = 130, height = 120, units = "mm")
print(glue::glue("{Sys.time()} -- done"))
