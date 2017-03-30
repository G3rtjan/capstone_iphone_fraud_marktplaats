
# We have gathered iPhone ads (including images) from Marktplaats during Dec16 - Feb17 using a scheduled web scraper on google cloud (check out:
# https://github.com/G3rtjan/capstone_iphone_fraud_marktplaats) and the results are stored in a google bucket

# NOTE: Optionally, you can skip this entire script and just download the results!

#### Download resulting data (instead of running this script) ####

# HOW TO: Download to /data (which is .gitignored) before proceding:
  # install gsutils https://cloud.google.com/storage/docs/gsutil_install
  # download to capstone_iphone_fraud_marktplaats/data folder with these bash commands:
  # NOTE: first cd to capstone_iphone_fraud_marktplaats location!
  # gsutil -m cp -R gs://eu.artifacts.capstoneprojectgt.appspot.com/mpdata data
  # if you want to view ad images in the shiny app, also download the image (~4 hours, slow...)
  # gsutil -m cp -R gs://eu.artifacts.capstoneprojectgt.appspot.com/mpimages data


#### Setup ####
# NOTE: You need to set the working directory to the location of this script!

# Load packages
devtools::install_github("timvink/mpscraper",ref = "master")
library(mpscraper)
library(magrittr)

# Load local functions from /functions folder
purrr::walk(list.files("functions", full.names = T), source)

# Run test scripts
try(testthat::test_dir("../tests/testthat/"))


#### Settings #### 
# Google Cloud settings
settings <- list(
  project = "capstoneprojectgt",
  # Cloud Storage settings
  scope = "https://www.googleapis.com/auth/devstorage.full_control",
  imageDir = "mpimages",
  # BigQuery settings
  bq_dataset = "mplaats_ads", 
  bq_table = "all_ads",
  bq_logs = "logs",
  bq_settings = "settings"
)


#### Download raw data ####
# Get all closed ads
closed_ads <- bigrquery::query_exec(
  query = sprintf(
    "SELECT ad_id FROM [%s:%s.%s] WHERE closed = 1 GROUP BY ad_id ORDER BY ad_id",
    settings$project,
    settings$bq_dataset,
    settings$bq_table
  ),
  project = settings$project, 
  max_pages = Inf
)

# Get all dates on which was scraped
all_scrape_dates <- bigrquery::query_exec(
  query = sprintf(
    "SELECT * FROM (SELECT DATE(time_retrieved) as scrape_date FROM [%s:%s.%s] WHERE closed = 0) q1 GROUP BY scrape_date ORDER BY scrape_date",
    settings$project,
    settings$bq_dataset,
    settings$bq_table
  ),
  project = settings$project, 
  max_pages = Inf
)

# Function to get data from all ads in batches
download_ads_scraped_on_date <- function(scrape_date, storage_dir, closed_ads, overwrite = F) {
  # Define path to the file
  file_path <- file.path(storage_dir,paste0("mp_data_scraped_on_",gsub("-","",scrape_date),".RData"))
  # Only download if required
  if (overwrite | !file.exists(file_path)) {
    cat(paste0("\n",format(Sys.time(), "%H:%M:%S"),": Downloading data for scrape date: ",scrape_date))
    data <- bigrquery::query_exec(
      query = sprintf(
        "SELECT * FROM [%s:%s.%s] WHERE DATE(time_retrieved) = '%s'",
        settings$project,
        settings$bq_dataset,
        settings$bq_table,
        scrape_date
      ),
      project = settings$project,
      max_pages = Inf
    ) %>% 
      dplyr::mutate(closed = ifelse(ad_id %in% closed_ads, 1.0, 0.0))
    cat(paste0(format(Sys.time(), "%H:%M:%S"),": Saving data for scrape date: ",scrape_date))
    saveRDS(object = data,file = file_path)
  } else {
    cat(paste0("\n",format(Sys.time(), "%H:%M:%S"),": Data already exists for scrape date: ",scrape_date))
  }
}
# Apply function
all_scrape_dates[['scrape_date']] %>% 
  purrr::walk(
    .f = download_ads_scraped_on_date,
    storage_dir = tempdir(),
    closed_ads = closed_ads[['ad_id']]
  )

# Combine all add data in single RData file
all_adds <- dir(path = tempdir(), pattern = ".RData", full.names = T) %>% 
  purrr::map_df(readRDS) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::filter(!is.na(ad_id) & !is.na(cp_id) & !is.na(displayed_since))

# Save combined ads data
saveRDS(all_adds, "../data/mpdata/full_mp_data.RData")


#### Enrich data with 'removed' merchant indicator ####

# Get all unique merchants with n open adds
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

# Save removed merchant info
saveRDS(removed_merchants, "../data/mpdata/removed_merchants.RData")

# Add to all_adds data
all_adds_extended <- dplyr::inner_join(
    x = all_adds,
    y = removed_merchants,
    by = c("cp_id","counterparty")
  ) %>% 
  dplyr::arrange(cp_id,ad_id,time_retrieved)

# Save enriched file
saveRDS(all_adds_extended, "../data/mpdata/full_mp_data.RData")


#### Aggregate data per ad ####

# Aggregate ads data into single row per ad
all_ads_info <- all_adds_extended %>%
  dplyr::mutate(
    price_value = extract_price(price),
    has_price = !is.na(price_value),
    sales_method = ifelse(has_price,NA,price),
    shipping_costs_value = extract_price(shipping_costs)
  ) %>% 
  dplyr::group_by(cp_id,ad_id,displayed_since,n_ads) %>% 
  dplyr::summarize(
    # Collapse changes in title/merchant name
    title = collapse_unique(title),
    counterparty = collapse_unique(counterparty),
    # Aggregate price info
    sales_method = collapse_unique(sales_method),
    has_price = any(has_price),
    lowest_price = min(price_value,na.rm = T),
    highest_price = max(price_value,na.rm = T),
    price_has_changed = (lowest_price != highest_price),
    shipping_method = collapse_unique(shipping),
    shipping_costs = max(shipping_costs_value, na.rm = T),
    # Aggregate retrieval information
    number_of_times_retrieved = length(unique(time_retrieved)),
    first_time_retrieved = min(time_retrieved,na.rm = T),
    last_time_retrieved = max(time_retrieved,na.rm = T),
    days_ad_was_followed = floor((last_time_retrieved - first_time_retrieved)/(60*60*24)),
    # Aggregate bid information
    biddings_active = any(biddings_active),
    number_of_biddings = max(0, biddings_n, na.rm = T),
    number_of_unique_bidders = max(0, biddings_unique_bidders, na.rm = T),
    minimum_highest_bid = min(biddings_highest_bid, na.rm = T),
    maximum_highest_bid = max(biddings_highest_bid, na.rm = T),
    minimum_lowest_bid = min(biddings_lowest_bid, na.rm = T),
    maximum_lowest_bid = max(biddings_lowest_bid, na.rm = T),
    # Aggregate iPhone characteristics
    condition = collapse_unique(conditie),
    subscription = collapse_unique(abonnement),
    model = collapse_unique(model),
    colour = collapse_unique(kleur),
    simlock = collapse_unique(simlock),
    must_be_sold_quickly = any(moet_nu_weg == "Moet nu weg"),
    # Other info
    closed = max(closed, na.rm = T),
    number_of_views = max(views, na.rm = T),
    number_of_favorites = max(favorites, na.rm = T),
    was_reserved = any(reserved == "Gereserveerd"),
    number_of_photos = max(0, number_of_photos, na.rm = T)
  ) %>% 
  dplyr::ungroup() %>%
  # Fixate date formats
  dplyr::mutate(
    first_time_retrieved = as.character(first_time_retrieved),
    last_time_retrieved = as.character(last_time_retrieved)
  )

# Save aggregated data
saveRDS(all_ads_info, "../data/mpdata/agg_mp_data.RData")


#### Store descriptions data separately ####

# Get all ad texts
all_ads_texts <- all_adds_extended %>%
  dplyr::select(cp_id,ad_id,description,time_retrieved) %>%
  dplyr::group_by(cp_id,ad_id,description) %>% 
  dplyr::summarise(
    from = min(time_retrieved, na.rm = T),
    to = max(time_retrieved, na.rm = T)
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::arrange(cp_id,ad_id,from) %>% 
  # Fixate date formats
  dplyr::mutate(
    from = as.character(from),
    to = as.character(to)
  )

# Save aggregated data
saveRDS(all_ads_texts, "../data/mpdata/text_mp_data.RData")


#### Create image hashing table ####

# For printing progress
i <- 0

# List all images
image_hash_table <- list.files("../data/mpimages", full.names = T) %>% 

# Create image hash table
image_hash_table <- image_hash_table
  purrr::map_df(hash_image) %>% 
  dplyr::mutate(
    ad_id = gsub("_.*","",image),
    image_nr = image %>% 
      gsub(".*_","",.) %>% 
      gsub("\\..*","",.) %>% 
      as.numeric()
  ) %>% 
  dplyr::group_by(hash) %>% 
  dplyr::mutate(
    n_ads_with_same_image = length(unique(ad_id)),
    n_cps_with_same_image = length(unique(cp_id))
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::arrange(ad_id,image_nr)

# Save image hash table
saveRDS(image_hash_table, "../data/mpdata/image_hash_table.RData")


