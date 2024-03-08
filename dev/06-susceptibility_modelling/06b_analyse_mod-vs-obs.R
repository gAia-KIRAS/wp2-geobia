# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# mod vs obs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("dplyr")
  library("tidyr")
  library("ggplot2")
  library("scattermore")
  library("lvplot")
  library("glue")
  library("qs")
  library("showtext")
})

print(glue::glue("{Sys.time()} -- loading data"))

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

ncores <- 16L

mod_type <- "random_forest"
# mod_type <- "earth"
# mod_type <- "earth_esa"

res <- qread(glue("dat/processed/prediction/mod-vs-obs/{mod_type}.qs"), nthreads = ncores)

p <- ggplot(res, aes(x = mean_susc, y = sd_susc)) +
  geom_scattermore(alpha = 0.1) +
  xlab("mean") +
  ylab("standard deviation") +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 20
    )
  )
ggsave(glue("plt/mean-vs-sd_{mod_type}_scatter.png"), p, width = 120, height = 120, units = "mm")


p <- ggplot(res, aes(x = mean_susc, y = sd_susc)) +
  geom_hex() +
  xlab("mean") +
  ylab("standard deviation") +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 20
    )
  )
ggsave(glue("plt/mean-vs-sd_{mod_type}_hex.png"), p, width = 140, height = 120, units = "mm")

print(glue::glue("{Sys.time()} -- analysis of positive instances"))
pos <- res |>
  filter(slide == TRUE) |>
  select(slide, mean_susc, sd_susc) |>
  arrange(-mean_susc) |>
  mutate(nrank = 1:n() / n())

q95 <- pos |>
  filter(nrank >= quantile(nrank, 0.95)) |>
  slice(1) |>
  pull(mean_susc)
print(glue::glue("    Q95: {round(q95,4)}"))

q80 <- pos |>
  filter(nrank >= quantile(nrank, 0.8)) |>
  slice(1) |>
  pull(mean_susc)
print(glue::glue("    Q80: {round(q80,4)}"))

nrow(res)
high <- sum(res$mean_susc >= q80)
medium <- sum(res$mean_susc >= q95) - high
low <- nrow(res) - high - medium

print(glue::glue("    high: n = {high} | rel: {round(high/nrow(res),4)*100}%"))
print(glue::glue("    medium: n = {medium} | rel: {round(medium/nrow(res),4)*100}%"))
print(glue::glue("    low: n = {low} | rel: {round(low/nrow(res),4)*100}%"))

susc_class <- res |>
  select(slide, susc_num = mean_susc) |>
  mutate(susc_class = if_else(susc_num < q95, 3, if_else(susc_num < q80, 2, 1)))

print(glue::glue("{Sys.time()} -- decreasing rank order plot"))
p <- ggplot(pos, aes(x = nrank, y = mean_susc)) +
  geom_vline(xintercept = 0.95, linetype = "dashed") +
  geom_vline(xintercept = 0.80, linetype = "dashed") +
  geom_line() +
  scale_x_continuous(name = "landslide scars", labels = scales::percent) +
  scale_y_continuous(name = "landslide susceptibility", labels = scales::percent, limits = c(0, 1)) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 40
    )
  )

ggsave(glue("plt/drop_{mod_type}.png"), p, width = 120, height = 120, units = "mm")

print(glue::glue("{Sys.time()} -- plotting susc distribution per observed class"))
p <- ggplot(res, aes(x = slide, y = mean_susc, fill = slide)) +
  geom_lv(color = "black", show.legend = FALSE) +
  xlab("observed event occurrence") +
  ylab("landslide susceptibility") +
  # guides(fill = guide_legend(title = "event occurrence")) +
  scale_fill_manual(values = c("#56B4E9", "#E69F00")) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 40
    ),
    legend.position = "bottom"
  )

ggsave(glue("plt/mod-vs-obs_{mod_type}.png"), p, width = 120, height = 120, units = "mm")
