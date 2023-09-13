suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
})

dat <- read_ipc_file("dat/processed/carinthia_10m.arrow")

dat |>
  filter(slide == 2) |>
  mutate(slide = TRUE) |>
  write_ipc_file(sink = "dat/processed/chunks/pos/pos_v.arrow", compression = "lz4")
dat |>
  filter(slide == 1) |>
  mutate(slide = TRUE) |>
  write_ipc_file(sink = "dat/processed/chunks/pos/pos_n.arrow", compression = "lz4")

neg <- dat |>
  filter(slide == 0) |>
  mutate(slide = FALSE)

partition_size <- nrow(neg) / 10

neg |>
  mutate(partition = rep(1:10, each = partition_size)) |>
  group_by(partition) %>%
  write_dataset("dat/processed/chunks/neg", format = "ipc")
