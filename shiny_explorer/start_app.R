
#### SETUP ####

# NOTE: You need to set the working directory to the location of this script!

# Load packages
library(magrittr)

# Load local functions from /functions folder
purrr::walk(list.files("functions", full.names = T), source)


#### LOAD DATA ####

# Get all adds data
all_ads <- readRDS("../data/mpdata/full_mp_data.RData")

# Read descriptions data
all_ads_texts <- readRDS(file = "../data/mpdata/text_mp_data.RData")

# Read aggregated ads data
all_ads_info <- readRDS(file = "../data/mpdata/agg_mp_data.RData")

# List all images
all_images <- dir(
      path = "../data/mpimages",
    full.names = T
  ) %>% 
  tibble::tibble(file_path = .) %>%
  dplyr::mutate(
    file_path = paste0("../",file_path),
    ad_id = basename(file_path) %>% 
      gsub("_.*","",.),
    image_nr = basename(file_path) %>% 
      gsub(".*_","",.) %>% 
      gsub("\\..*","",.) %>% 
      as.numeric()
  )


#### TRANSFORM DATA ####

# Create overview of ads
ads_overview <- all_ads_info %>% 
  dplyr::select(ad_id,counterparty,cp_id) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::group_by(cp_id) %>% 
  dplyr::mutate(counterparty = collapse_unique(counterparty)) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(cp_info = paste0(counterparty," - (",cp_id,")")) %>% 
  dplyr::arrange(cp_info,ad_id)

# Create overview of all merchants and ads
merchants <- setNames(object = ads_overview$cp_id,nm = ads_overview$cp_info)
ads <- setNames(object = ads_overview$ad_id,nm = ads_overview$ad_id)


#### START APP ####

# Create global variables for Shiny app
global_vars <- list(
  all_images = all_images,
  all_ads_texts = all_ads_texts,
  all_ads_info = all_ads_info,
  ads_overview = ads_overview,
  merchants = merchants,
  ads = ads,
  selectizers = c(merchants,ads)
)

# Run the app
shiny::runApp("app",launch.browser = T)


