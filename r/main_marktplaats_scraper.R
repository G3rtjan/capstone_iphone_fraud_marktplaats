
#####################################
#### Awesome marktplaats scraper ####
#####################################
# This script is run by crontab on an docker container running on google compute engine 
# Results are saved to google bigquery
# Details https://github.com/G3rtjan/capstone_iphone_fraud_marktplaats


#### Setup ####
devtools::install_github("timvink/mpscraper",ref="production") # not installed in the docker container yet
library(mpscraper)
library(magrittr)

purrr::walk(list.files("functions", full.names = T), source)
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

# Initialize bigquery dataset
initialize_bigquery_dataset(
  project = settings$project, 
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_table
)

# Download scrape settings
scrape_settings <- get_settings_from_bigquery(
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_settings
)
# Combine all settings
settings <- c(settings,as.list(scrape_settings))


#### Reset Settings ####
# Enable reset of scrape settings
if(FALSE) {
  # Reset scrape settings
  reset_settings_in_bigquery(
    project = settings$project, 
    bq_dataset = settings$bq_dataset, 
    bq_table = settings$bq_settings,
    new_scrape_settings = list(
      # mpscraper settings
      search_url = "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex",
      ads_per_minute = 300, # limit download rate to prevent being blocked by hammering marktplaats server
      report_every_nth_scrape = 100, # how chatty do you want to be
      number_of_tries = 3, # in case of connection time-outs
      scrape_interval = 4, # interval between two scrapes, in hours
      # BigQuery settings
      batch_size = 100
    )
  )
}


#### Start logging ####
log_items <- list(
  start_time = Sys.time()
)


#### Scrape ad info ####
# Get all open ads from google bigquery
open_ads <- get_ads_from_bigquery(
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_table,
  method = "open"
)

# Get all currently listed ads from marktplaats
tryCatch(expr = {
  listed_ads <- list_advertisements(
    url = settings$search_url,
    advertisement_type = "individuals" #,max_pages = 3
  )
},finally = {
  listed_ads <- data.frame(ad_id = open_ads$ad_id[1])
})

# Determine which ads to scrape
ads_to_scrape <- determine_ads_to_scrape(
  ads_listed = listed_ads, 
  ads_seen = open_ads,
  scrape_interval_h = settings$scrape_interval
)

# Create batches
batches <- split(ads_to_scrape, ceiling(seq_along(ads_to_scrape)/settings$batch_size))
# Create empty results table
scraped_ads <- data.frame()

# Scrape and upload them per batch
for(batch in batches) {
  try({
    # Get all open ads from google bigquery
    to_scrape <- get_ads_from_bigquery(
      project = settings$project,
      bq_dataset = settings$bq_dataset,
      bq_table = settings$bq_table,
      method = "open"
    ) %>% 
      dplyr::filter(ad_id %in% batch) %>% 
      dplyr::mutate(time_since_last_scrape = difftime(Sys.time(),last_scrape,units="hours")) %>% 
      dplyr::filter(time_since_last_scrape >= settings$scrape_interval) %>% 
      dplyr::arrange(-time_since_last_scrape)
    # Scrape batch of ads
    if(dim(to_scrape)[1] > 0) {
      scraped <- scrape_ads(
        ad_ids = to_scrape$ad_id,
        ads_per_minute = settings$ads_per_minute,
        report_every_nth_scrape = settings$report_every_nth_scrape,
        number_of_tries = settings$number_of_tries
      )
      # Upload batch of scraped ads to bigquery
      upload_ads_to_bigquery(
        scraped_ads = scraped,
        project = settings$project,
        bq_dataset = settings$bq_dataset,
        bq_table = settings$bq_table,
        batch_size = settings$batch_size
      )
      # Add them to total set
      scraped_ads <- dplyr::bind_rows(scraped_ads,scraped)
    }
  })
}

# Add log items
log_items$n_rows_scraped <- nrow(scraped_ads)
log_items$n_cols_scraped <- ncol(scraped_ads)
log_items$n_new_ads <- sum(!scraped_ads$ad_id %in% open_ads$ad_id)
log_items$n_existing_ads <- sum(scraped_ads$ad_id %in% open_ads$ad_id)
log_items$end_time_scraping <- Sys.time()


#### Determine ad images to scrape ####
# Set scope
options(googleAuthR.scopes.selected = c(settings$scope))
# Authentication
googleCloudStorageR::gcs_auth()
# Get bucket and bucket info
bucket <- googleCloudStorageR::gcs_list_buckets(settings$project)
bucket_info <- googleCloudStorageR::gcs_get_bucket(bucket$name)
# Get bucket objects
#objects <- googleCloudStorageR::gcs_list_objects(bucket$name) # NOT CORRECTLY IMPLEMENTED, LIMITED TO 1000 RESULTS!
objects <- get_add_images_from_gcloud(
  bucket_name = bucket$name,
  prefix = settings$imageDir
)

# Create filter for images which have already been collected
gathered_images <- data.frame(name = objects) %>%
  dplyr::filter(grepl(settings$imageDir,name)) %>% 
  dplyr::mutate(ad_id = as.character(stringr::str_extract(name,'[am][0-9]{1,10}'))) %>% 
  dplyr::filter(grepl("[mM|aA][0-9]{9}", ad_id)) %>% 
  dplyr::select(ad_id) %>% 
  dplyr::distinct(.keep_all = T)

# Get ads to collect images for
ads_with_images <- get_ads_with_images(
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_table
)
# Apply filter
ads_to_get_images_for <- ads_with_images[!ads_with_images %in% gathered_images$ad_id]

# Add log items
log_items$n_new_ads_with_images <- length(ads_to_get_images_for)


#### Scrape and upload ad images ####
dir.create(settings$imageDir)
# Scrape and upload all images
list(
  ad_id = ads_to_get_images_for,
  file_path = settings$imageDir,
  bucket_name = bucket$name
) %>% 
  purrr::pwalk(upload_ad_images_to_gcloud)

# Add log items
log_items$n_new_images <- length(list.files(settings$imageDir))
log_items$end_time_uploading_images <- Sys.time()
duration_in_mins <- function(start,end) paste0(round(as.numeric(difftime(start,end,units="mins")),1),' minutes')
log_items$duration_scraping <- duration_in_mins(log_items$end_time_scraping,log_items$start_time)
log_items$duration_uploading_images <- duration_in_mins(log_items$end_time_uploading_images,log_items$end_time_scraping)
log_items$total_time <- duration_in_mins(log_items$end_time_uploading_images,log_items$start_time)

# Cleanup
unlink(settings$imageDir, recursive=TRUE)


#### Upload logs ####
# Upload logs to bigquery
upload_log_to_bigquery(
  logs = data.frame(log_items),
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_logs
)


