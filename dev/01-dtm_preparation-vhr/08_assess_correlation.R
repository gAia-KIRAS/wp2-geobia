library(stars)
library(parallel)
library(dplyr)
library(tidyr)
library(corrr)

fl <- list.files(
  "dat/interim/dtm_derivates/ktn_Nockberge_Ost",
  pattern = "tif", full.names = TRUE
)

param <- gsub("(dat/interim/dtm_derivates/ktn_Nockberge_Ost/dtm_carinthia_Nockberge_Ost_)(.*)(.tif)", "\\2", fl)

dem_to_mat <- function(x) {
  tif <- read_stars(x, RasterIO = list(nBufXSize = 50, nBufYSize = 50, bands = 1), proxy = FALSE)
  res <- unclass(tif)[[1]]
  res <- as.vector(res)
  return(res)
}

tifs <- mclapply(fl, dem_to_mat, mc.cores = 12L)
names(tifs) <- param

cor_dat <- tifs %>%
  bind_rows() %>%
  select(-`channel-network`, -`watershed-basins`) %>%
  drop_na() %>%
  cor() %>%
  as.data.frame() %>%
  rownames_to_column(var = "param_1") %>%
  pivot_longer(-param_1, names_to = "param_2", values_to = "correlation") %>%
  mutate(cor = round(correlation, 2))

p <- ggplot(cor_dat, aes(x = param_1, y = param_2, fill = correlation)) +
  geom_tile(show.legend = FALSE) +
  geom_text(aes(label = cor), size = 2) +
  coord_equal() +
  scale_fill_gradient2(limits = c(-1, 1)) +
  xlab("") +
  ylab("") +
  theme_linedraw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

ggsave("plt/dtm_correlation_heatmap.png", height = 250, width = 250, units = "mm", dpi = 300)
