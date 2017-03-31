
#### SETUP ####

# NOTE: You need to set the working directory to the location of this script!

# Load packages
devtools::install_github("timvink/mpscraper", ref = "production")
library(mpscraper)
library(magrittr)
library(caret)
library(xgboost)

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

# Load training data
training <- readRDS(file = "../data/model/training_data.RData")


#### TRANSFORM DATA ####

# Add additonal columns to ads info
all_ads_info <- all_ads_info %>% 
  dplyr::mutate(
    counterparty_is_removed = ifelse(n_ads == "Removed", "Yes", "No")
  )

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


#### SCRAPE NEW DATA ####

# Get overview of all available iPhone ads
listed_ads <- mpscraper::list_advertisements(
  url = "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex",
  advertisement_type = "individuals"
)

# Create directory for new images
new_image_dir <- "../data/newmpimages"
if (!dir.exists(new_image_dir)) {
  dir.create(new_image_dir)
}


#### LOAD MODEL ####

# Load scaling model
scaling_model = readr::read_rds("../data/model/pre_proc_scaling_model.RData")

# Load fraud model
fraud_model = readr::read_rds("../data/model/fraud_detection_model.RData")

# Load average iPhone model prices
model_prices = readRDS("../data/model/mean_model_prices.RData")

# Load all image hashes
image_hashes = readRDS("../data/mpdata/image_hash_table.Rdata")


#### START APP ####

# Create global variables for Shiny app
global_vars <- list(
  # For training ads
  all_images = all_images,
  all_ads_texts = all_ads_texts,
  all_ads_info = all_ads_info,
  ads_overview = ads_overview,
  merchants = merchants,
  ads = ads,
  selectizers = c(merchants,ads),
  # For new ads
  new_ads = unique(listed_ads$ad_id),
  scaling_model = scaling_model,
  fraud_model = fraud_model,
  model_prices = model_prices,
  image_hashes = image_hashes,
  image_dir = paste0("../",new_image_dir)
)

# Run the app
shiny::runApp("app",launch.browser = T)


