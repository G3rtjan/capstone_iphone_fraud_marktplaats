
################################################
#### Find fraudulent marktplaats iPhone ads ####
################################################

# We have gathered iPhone ads (including images) from ??Dec-16 - ??Feb17 using a scheduled web scraper
# The results are stored in a google bucket
# Download to /data (which is .gitignored) before proceding

#### download data ### 

  # install gsutils https://cloud.google.com/storage/docs/gsutil_install
  # download to capstone_iphone_fraud_marktplaats/data folder with these bash commands:
  # NOTE: first cd to capstone_iphone_fraud_marktplaats location!
  # gsutil -m cp -R gs://eu.artifacts.capstoneprojectgt.appspot.com/mpdata data
  # gsutil -m cp -R gs://eu.artifacts.capstoneprojectgt.appspot.com/mpimages data

#### setup #### 

library(googleAuthR)
library(googleCloudStorageR)
library(tidyverse)
library(OpenImageR)
devtools::install_github("timvink/mpscraper",ref = "master") # not installed in the docker container yet
library(mpscraper)

purrr::walk(list.files("functions", full.names = T), source)

#### Aggregate data #### 

# image hash map
i <- 0 # for printing
image_hash_table <- list.files("../data/mpimages", full.names = T) %>% 
  purrr::map_df(hash_image) %>% 
  dplyr::mutate(
    ad_id = gsub("_.*","",image),
    image_nr = image %>% 
      gsub(".*_","",.) %>% 
      gsub("\\..*","",.) %>% 
      as.numeric()
  ) %>% 
  dplyr::group_by(hash) %>% 
  dplyr::mutate(n_ads_with_same_image = length(unique(ad_id))) %>% 
  dplyr::ungroup() %>% 
  dplyr::arrange(ad_id,image_nr)
saveRDS(image_hash_table, "../data/mpdata/image_hash_table.RData")


# ads data 

# merchant data
# Get all adds data
all_adds <- readRDS("../data/mpdata/full_mp_data.RData")

# Get all unique merchants with n open adds (or indication 'Removed')
all_merchants <- all_adds %>% 
  dplyr::select(cp_id,counterparty) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::arrange(cp_id,counterparty)

# Create empty results tibble
removed_merchants <- tibble::tibble()
# Loop per 100 merchants
for (i in 1:nrow(all_merchants)) {
  merchant <- all_merchants[i,]
  removed <- get_n_current_advs_of_merchant(merchant$cp_id)
  if (removed == "Removed") {
    cat(paste0("\nMerchant number ",i," has been ",removed))
  } else {
    cat(paste0("\nMerchant number ",i," has ",removed," ads"))
  }
  removed_merchants <- dplyr::bind_rows(
    removed_merchants,
    merchant %>% 
      dplyr::mutate(n_ads = removed)
  )
}

# Add to all_adds data
all_adds_extended <- dplyr::inner_join(
    x = all_adds,
    y = removed_merchants,
    by = c("cp_id","counterparty")
  ) %>% 
  dplyr::arrange(cp_id,ad_id,time_retrieved)

# Save new file
saveRDS(all_adds_extended, "../data/mpdata/full_mp_data.RData")


