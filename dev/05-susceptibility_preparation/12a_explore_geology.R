library("tidyverse")
library("arrow")
library("showtext")

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

lut <- read_csv("doc/lut/lut_lithology_200k_reclass_de.csv")
pos <- read_ipc_file("dat/processed/chunks/pos/carinthia_slides.arrow") |>
  mutate(lithology = as.integer(as.character(lithology))) |>
  left_join(lut, by = join_by(lithology == id)) |>
  select(lithology, name) |>
  drop_na(lithology)

p <- ggplot(pos, aes(y = name)) +
  geom_bar() +
  theme_linedraw() +
  xlab("Anzahl") +
  ylab("Geologie (Klasse)") +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 20
    )
  )

ggsave("plt/events_per_geological_class.png", p, width = 150, height = 100, units = "mm")
