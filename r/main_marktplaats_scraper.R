
#####################################
#### Awesome marktplaats scraper ####
#####################################
# This script is run by crontab on an docker container running on google compute engine 
# Results are saved to google bigquery
# Details https://github.com/G3rtjan/capstone_iphone_fraud_marktplaats


#### SETUP ####
devtools::install_github("timvink/mpscraper") # not installed in the docker container yet
library(mpscraper)
library(magrittr)

purrr::walk(list.files("functions", full.names = T), source)
try(testthat::test_dir("../tests/testthat/"))

#### Settings #### 

settings <- list(
  # BigQuery settings
  project = "polynomial-coda-151914",
  bq_dataset = "mplaats_ads", 
  bq_table = "all_ads",
  bq_logs = "logs",
  bq_settings = "settings"
)

#### Logging ####
log_items <- list(
  start_time = Sys.time()
)

# Initialize bigquery dataset
initialize_bigquery_dataset(project = settings$project, bq_dataset = settings$bq_dataset,bq_table = settings$bq_table)

# Download scrape settings
scrape_settings <- get_settings_from_bigquery(
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_settings
)
# Combine all settings
settings <- c(settings,as.list(scrape_settings))

# Get all open ads from google bigquery
open_ads <- get_ads_from_bigquery(
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_table,
  method = "open",
  scrape_interval_h = settings$scrape_interval
)

# Get all currently listed ads from marktplaats
listed_ads <- list_advertisements(
  url = settings$search_url,
  advertisement_type = "individuals" #,max_pages = 3
)

# Determine which ads to scrape, and scrape 'em!
scraped_ads <- determine_ads_to_scrape(
    ads_listed = listed_ads$ad_id, 
    ads_seen = open_ads
  ) %>% 
  scrape_ads(
    ads_per_minute = settings$ads_per_minute,
    report_every_nth_scrape = settings$report_every_nth_scrape,
    number_of_tries = settings$number_of_tries
  )

# Add log items
log_items$n_rows_scraped <- nrow(scraped_ads)
log_items$n_cols_scraped <- ncol(scraped_ads)
log_items$end_time_scraping <- Sys.time()
  
# Upload scraped ads to bigquery
upload_ads_to_bigquery(
  scraped_ads = scraped_ads,
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_table,
  batch_size = settings$batch_size
)

duration_in_mins <- function(start,end) paste0(round(as.numeric(difftime(start,end,units="mins")),1),' minutes')

# Add log items
log_items$end_time_uploading <- Sys.time()
log_items$duration_scraping <- duration_in_mins(log_items$end_time_scraping,log_items$start_time)
log_items$duration_uploading <- duration_in_mins(log_items$end_time_uploading,log_items$end_time_scraping)
log_items$total_time <- duration_in_mins(log_items$end_time_uploading,log_items$start_time)

# Upload logs to bigquery
upload_log_to_bigquery(
  logs = data.frame(log_items),
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_logs
)


