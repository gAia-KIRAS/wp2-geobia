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

n_part <- 20
partition_size <- nrow(dat) / n_part
mod <- nrow(dat) %% n_part
partition <- c(rep(1:(n_part - 1), each = partition_size), rep(n_part, partition_size + mod))
stopifnot(length(partition) == nrow(dat))

dat |>
  mutate(partition = partition) |>
  group_by(partition) %>%
  write_dataset("dat/processed/chunks/all", format = "ipc")

print(glue::glue("{Sys.time()} -- DONE"))
