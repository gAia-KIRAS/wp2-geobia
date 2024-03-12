print(glue::glue("{Sys.time()} -- loading packages"))

suppressPackageStartupMessages({
  library("tidyverse")
  library("glue")
  library("qs")
  library("colorspace")
  library("showtext")
  library("GGally")
})

ncores <- 16L

# specify plot type: full (all features) vs reduced (selected features)
type <- "full"
# type <- "reduced"

source("wp2-geobia/dev/utils.R")

font_add("Source Sans Pro", "~/.fonts/source-sans-pro/SourceSansPro-Regular.otf")
showtext_auto()

fullnames <- read_csv("doc/data_description/lut_vars.csv") %>%
  select(-progenitor) %>%
  mutate(feature_name = gsub(
    pattern = "30-day standardized precipitation evapotranspiration index",
    replacement = "30-day SPEI",
    x = feature_name
  ))

dat <- qread("wp2-geobia/dat/processed/gaia_noe_balanced_iters.qs", nthreads = ncores) %>%
  mutate(across(everything(), as.numeric))

if (type == "reduced") {
  dat <- dat %>%
    select(
      -elevation, -maximum_height, -wei,
      -roughness, -tri, -svf,
      -pto, -nto, -curv_max, -curv_min, -dah,
      -flow_path_length, -flow_width, -sca,
      -api_k7, -api_k30, -rx1day, -rx5day, -sdii,
      -forest_cover,
      -road_dist,
      -sw_hazard_cat, -sw_max_depth, -sw_max_speed,
      -esa, -x, -y
    )
}

res <- dat %>%
  filter(iter == 1 & slide == 1) %>%
  bind_rows(filter(dat, slide == 0)) %>%
  select(-iter)

cn <- colnames(res)
corrs <- crossing(cn, cn)
corr <- map2_dbl(corrs$cn...1, corrs$cn...2, compute_corr, .progress = TRUE)

corrs <- corrs %>%
  mutate(correlation = corr) #%>%
  #left_join(fullnames, by = join_by("cn...1" == "feature_shortname")) %>%
  # rename(feature_1 = feature_name) %>%
  #left_join(fullnames, by = join_by("cn...2" == "feature_shortname")) %>%
  # rename(feature_2 = feature_name)

corrs %>%
  filter(correlation < 1) %>%
  mutate(corr_abs = abs(correlation)) %>%
  arrange(-corr_abs)

p <- ggplot(corrs, aes(x = cn...1, y = cn...2)) +
  geom_raster(aes(fill = correlation)) +
  xlab("") +
  ylab("") +
  scale_fill_continuous_diverging("Vik", limits = c(-1, 1)) +
  theme_linedraw() +
  theme(
    text = element_text(
      family = "Source Sans Pro",
      colour = "black",
      size = 7
    )
    ,
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
    legend.position = "right"
  )

ggsave(glue("wp2-geobia/plt/correlation_tuning_{type}.png"), p, width = 130, height = 120, units = "mm")
print(glue::glue("{Sys.time()} -- done"))



### check with carinthia data
colnames_carinthia <- c("slide", "aspect_arctan2", "convergence_index", "convexity",
"curv_max", "curv_min", "curv_plan", "curv_prof", "dah", "elevation",
"flow_accumulation", "flow_path_length", "flow_width", "geomorphons",
"maximum_height", "mrn", "nto", "pto", "roughness", "sca", "slope",
"spi", "svf", "tpi", "tri", "twi", "vrm", "wei", "land_cover",
"forest_cover", "tree_height", "cwd", "prcptot", "sdii", "rx5day",
"rx1day", "api_k7", "api_k30", "spei30", "pci", "sw_hazard_cat",
"sw_max_speed", "sw_max_depth", "sw_spec_runoff", "road_dist",
"lithology", "esa", "x", "y")

colnames_noe <- dput(colnames(res))
# c("slide", "aspect_arctan2", "convergence_index", "convexity", 
# "curv_max", "curv_min", "curv_plan", "curv_prof", "dah", "flow_accumulation", 
# "flow_path_length", "flow_width", "geomorphons", "maximum_height", 
# "mrn", "nh", "pto", "sca", "spi", "svf", "twi", "vrm", "watershed_basins", 
# "land_cover", "cwd", "prcptot", "sdii", "rx5day", "rx1day", "api_k7", 
# "api_k30", "spei30", "pci", "road_dist", "legend_fin", "x", "y", 
# "nto")


colnames_carinthia[which(colnames_noe %in% colnames_carinthia)]

# Common column names
common_columns <- intersect(colnames_carinthia, colnames_noe)
# > common_columns
#  [1] "slide"             "aspect_arctan2"    "convergence_index"
#  [4] "convexity"         "curv_max"          "curv_min"         
#  [7] "curv_plan"         "curv_prof"         "dah"              
# [10] "flow_accumulation" "flow_path_length"  "flow_width"       
# [13] "geomorphons"       "maximum_height"    "mrn"              
# [16] "nto"               "pto"               "sca"              
# [19] "spi"               "svf"               "twi"              
# [22] "vrm"               "land_cover"        "cwd"              
# [25] "prcptot"           "sdii"              "rx5day"           
# [28] "rx1day"            "api_k7"            "api_k30"          
# [31] "spei30"            "pci"               "road_dist"        
# [34] "x"                 "y"     

# Column names missing in res
missing_columns <- setdiff(colnames_carinthia, colnames_noe)

# > missing_columns
#  [1] "elevation"      "roughness"      "slope"          "tpi"           
#  [5] "tri"            "wei"            "forest_cover"   "tree_height"   
#  [9] "sw_hazard_cat"  "sw_max_speed"   "sw_max_depth"   "sw_spec_runoff"
# [13] "lithology"      "esa"  