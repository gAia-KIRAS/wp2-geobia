library(tidyverse)
library(colorspace)
library(showtext)
library(glue)

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.ttf")
showtext_auto()

source("dev/utils.R")

ids <- glue("iteration-{sprintf('%02d', 1:10)}")

wall("{Sys.time()} -- reading data")
lut_names <- read_csv("doc/data_description/lut_vars.csv")
rf_mods <- readRDS("dat/interim/mars/earth_mbo.rds")
imp_lst <- lapply(rf_mods, get_evimp)

# aggregated importance from models ----
imp <- imp_lst |>
  bind_rows(.id = "id") |>
  mutate(id = gsub("iteration-", "", id)) |>
  pivot_longer(cols = nsubsets:rss, names_to = "metric") |>
  group_by(index, metric) |>
  summarize(
    min_imp = min(value),
    mean_imp = mean(value),
    max_imp = max(value),
    .groups = "drop"
  ) |>
  left_join(lut_names, by = join_by("index" == "feature_shortname")) |>
  group_by(metric) |>
  arrange(-mean_imp) |>
  mutate(feature_name = fct_reorder(feature_name, -desc(mean_imp)))

p <- ggplot(imp, aes(x = feature_name, y = mean_imp, color = progenitor)) +
  geom_pointrange(aes(ymin = min_imp, ymax = max_imp)) +
  coord_flip() +
  xlab("feature") +
  ylab("permutation feature importance") +
  guides(color = guide_legend(title = "type")) +
  scale_color_discrete_qualitative("Dark3") +
  scale_alpha(range = c(0.4, 1), guide = "none") +
  facet_wrap(~metric) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 20
    ),
    legend.position = "right"
  )

ggsave("plt/importance.png", p, width = 180, height = 120, units = "mm")
