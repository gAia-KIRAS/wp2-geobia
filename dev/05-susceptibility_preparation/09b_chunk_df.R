suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
})

dat <- read_ipc_file("dat/processed/carinthia_10m.arrow")

# save RAM
# dat |>
#   filter(slide == TRUE) |>
#   write_ipc_file(sink = "dat/processed/chunks/pos/carinthia_slides.arrow", compression = "lz4")
#
# neg <- dat |>
#   filter(slide == FALSE)
#
# partition_size <- nrow(neg) / 9
#
# neg |>
#   mutate(partition = rep(1:9, each = partition_size)) |>
#   group_by(partition) %>%
#   write_dataset("dat/processed/chunks/neg", format = "ipc")
#
# print(glue::glue("{Sys.time()} -- DONE"))

partition_size <- nrow(dat) / 9
mod <- nrow(dat) %% 9
partition <- c(rep(1:8, each = partition_size), rep(9, partition_size + mod))

dat |>
  mutate(partition = partition) |>
  group_by(partition) %>%
  write_dataset("dat/processed/chunks/all", format = "ipc")

print(glue::glue("{Sys.time()} -- DONE"))
