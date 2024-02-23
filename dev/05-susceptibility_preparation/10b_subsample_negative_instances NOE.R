print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("dplyr")
  library("tidyr")
  library("qs")
  library("arrow")
  library("glue")
  library("sf")
  library("ggplot2")
  library("showtext")
})

source("wp2-geobia/dev/utils.R")

ncores <- 27L

wall("{Sys.time()} -- loading data sets")
# absence_grd <- absence_grid
absence_grd <- qread("wp2-geobia/dat/interim/aoi/gaia_neo_absence_grid.qs", nthreads = ncores) %>%
  select(neg_sample)

full <- read_ipc_file("wp2-geobia/dat/processed/noe_10m.arrow") %>%
  bind_cols(absence_grd) %>%
  drop_na()
rm(absence_grd)
gc()

# full_bcp <- full
# full <- full %>%
#   bind_cols(absence_grd) %>%
#   drop_na()



wall("{Sys.time()} -- subsetting positive instances")
pos_all <- full %>%
  filter(slide == TRUE) %>%
  select(-neg_sample)
print(nrow(pos_all))

# # for later when elevation and slope is provided:
# # elevation threshold
# qu <- 0.99
# thresh <- round(quantile(pos_all$elevation, qu) / 100) * 100
# thresh

# pos_all <- pos_all %>%
#   filter(elevation <= thresh)
# print(nrow(pos_all))

wall("{Sys.time()} -- subsetting negative instances")
neg_all <- full %>%
  filter(neg_sample == TRUE) %>%
  select(-neg_sample) # %>%
  # filter(elevation <= thresh) %>% # don't have elevation right now # to do: compute
  # mutate(pps = 1 / cos(slope * pi / 180)) # don't have slope # to do: compute

# create_balanced_subset <- function(seed, df_neg, df_pos) {
#   set.seed(seed)
#   tmp <- slice_sample(df_neg, n = nrow(df_pos), weight_by = pps, replace = FALSE) %>%
#     select(-pps)
#   out <- bind_rows(tmp, df_pos)
#   return(out)
# }

# for now:
create_balanced_subset <- function(seed, df_neg, df_pos) {
  set.seed(seed)
  tmp <- slice_sample(df_neg, n = nrow(df_pos), weight_by = nto, replace = FALSE) %>%
    select(-nto)
  out <- bind_rows(tmp, df_pos)
  return(out)
}

lapply(1:10, create_balanced_subset, df_neg = neg_all, df_pos = pos_all) %>%
  bind_rows(.id = "iter") %>%
  mutate(iter = as.integer(iter)) %>%
  qsave("wp2-geobia/dat/processed/gaia_noe_balanced_iters.qs", nthreads = ncores)
wall("{Sys.time()} -- subsampling completed")

wall("{Sys.time()} -- plotting")

tmp <- qread("wp2-geobia/dat/processed/gaia_noe_balanced_iters.qs", nthreads = ncores) %>%
  as_tibble() %>%
  select(iter, slide, x, y) %>%
  st_as_sf(coords = c("x", "y"), crs = 3416)

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

p <- ggplot(tmp) +
  geom_sf(aes(color = slide), size = 0.4, alpha = 0.5) +
  facet_wrap(~iter, ncol = 2) +
  theme_linedraw() +
  scale_color_manual(values = unname(c(okabe_ito["darkorange"], okabe_ito["darkblue"]))) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 10
    ),
    legend.position = "bottom"
  ) +
  guides(color = guide_legend(override.aes = list(size = 5, alpha = 1)))
ggsave(p, filename = "wp2-geobia/plt/balanced_subsets.png", width = 300, height = 280, units = "mm")

wall("{Sys.time()} -- DONE")
