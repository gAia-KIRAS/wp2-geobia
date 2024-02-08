# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# mod vs obs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("dplyr")
  library("tidyr")
  library("ggplot2")
  library("lvplot")
  library("glue")
  library("qs")
})

print(glue::glue("{Sys.time()} -- loading data"))

ncores <- 16L

mod_type <- "random_forest"
# mod_type <- "earth"
# mod_type <- "earth_esa"

res <- qread(glue("dat/processed/prediction/mod-vs-obs/{mod_type}.qs"), nthreads = ncores)

print(glue::glue("{Sys.time()} -- analysis of positive instances"))
pos <- res |>
  filter(slide == TRUE) |>
  select(slide, mean_susc, sd_susc) |>
  arrange(-mean_susc) |>
  mutate(nrank = 1:n() / n())

print(glue::glue("    Q95:"))

pos |>
  filter(nrank >= quantile(nrank, 0.95)) |>
  slice(1)

print(glue::glue("    Q80:"))
pos |>
  filter(nrank >= quantile(nrank, 0.8)) |>
  slice(1)

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
      size = 20
    )
  )

ggsave(glue("plt/drop_{mod_type}.png"), p, width = 200, height = 200, units = "mm")

print(glue::glue("{Sys.time()} -- plotting susc distribution per observed class"))
p <- ggplot(res, aes(x = slide, y = mean_susc, fill = slide)) +
  geom_lv(color = "black") +
  xlab("") +
  ylab("landslide susceptibility") +
  guides(fill = guide_legend(title = "event occurrence")) +
  scale_fill_manual(values = c("#56B4E9", "#E69F00")) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 20
    ),
    legend.position = "bottom"
  )

ggsave(glue("plt/mod-vs-obs_{mod_type}.png"), p, width = 200, height = 200, units = "mm")
