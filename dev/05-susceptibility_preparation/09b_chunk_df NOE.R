suppressPackageStartupMessages({
  library("dplyr")
  library("arrow")
  library("glue")
})

elev_thresh <- 1900

dat <- read_ipc_file("wp2-geobia/dat/processed/noe_10m.arrow")

n_full <- 57842689
n_selection <- 47038092
print(glue("Dropped {n_full - n_selection} instances above {elev_thresh} m"))
print(glue("Reduced data set size: {n_full} instances ({round(n_selection/n_full * 100, 2)} %)"))

# save RAM
# dat %>%
#   filter(slide == TRUE) %>%
#   write_ipc_file(sink = "dat/processed/chunks/pos/carinthia_slides.arrow", compression = "lz4")
#
# neg <- dat %>%
#   filter(slide == FALSE)
#
# partition_size <- nrow(neg) / 9
#
# neg %>%
#   mutate(partition = rep(1:9, each = partition_size)) %>%
#   group_by(partition) %>%
#   write_dataset("dat/processed/chunks/neg", format = "ipc")
#
# print(glue::glue("{Sys.time()} -- DONE"))

n_part <- 10
partition_size <- nrow(dat) / n_part
mod <- nrow(dat) %% n_part
partition <- c(rep(1:(n_part - 1), each = partition_size), rep(n_part, partition_size + mod))
stopifnot(length(partition) == nrow(dat))

dat %>%
  mutate(partition = partition) %>%
  group_by(partition) %>%
  write_dataset("wp2-geobia/dat/processed/chunks/all", format = "ipc")

print(glue::glue("{Sys.time()} -- DONE"))
