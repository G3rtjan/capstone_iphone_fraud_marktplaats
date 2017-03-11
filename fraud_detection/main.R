
################################################
#### Find fraudulent marktplaats iPhone ads ####
################################################

# We have gathered iPhone ads (including images) from ??Dec-16 - ??Feb17 using a scheduled web scraper
# The results are stored in a google bucket
# Download to /data (which is .gitignored) before proceding

#### download data ### 

  # install gsutils https://cloud.google.com/storage/docs/gsutil_install
  # download to capstone_iphone_fraud_marktplaats/data folder with these bash commands:
  # gsutil -m cp -R gs://eu.artifacts.capstoneprojectgt.appspot.com/mpdata data
  # gsutil -m cp -R gs://eu.artifacts.capstoneprojectgt.appspot.com/mpimages data

#### setup #### 

library(googleAuthR)
library(googleCloudStorageR)
library(tidyverse)
library(OpenImageR)

purrr::walk(list.files("functions", full.names = T), source)

#### Aggregate data #### 

# image hash map
i <- 0 # for printing
image_hash_table <- list.files("../data/mpimages", full.names = T) %>% 
  purrr::map_df(hash_image)
writeRDS(image_hash_table, "data/image_hash_table.RData")

# ads data 

# merchant data
# Get all adds data
all_adds <- readRDS("../data/full_mp_data.RData")

# Get all unique merchants with n open adds (or indication 'Removed')
all_merchants <- all_adds %>% 
  dplyr::select(cp_id,counterparty) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::arrange(cp_id,counterparty) %>% 
  dplyr::rowwise() %>% 
  dplyr::mutate(n_ads = get_n_current_advs_of_merchant(cp_id))





