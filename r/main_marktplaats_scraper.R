
#####################################
#### Awesome marktplaats scraper ####
#####################################
# This script is run by crontab on an docker container running on google compute engine 
# Results are saved to google bigquery
# Details https://github.com/G3rtjan/capstone_iphone_fraud_marktplaats


#### SETUP ####
library(mpscraper) # If you do not use the docker container, install using devtools::install_github("timvink/mpscraper")
library(purrr)

purrr::walk(list.files("functions", full.names = T), source)
try(testthat::test_dir("../tests/testthat/"))

#### Settings #### 

settings <- list(
  search_url = "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex",
  # mpscraper settings
  ads_per_minute = 50, # limit download rate to prevent being blocked by hammering marktplaats server
  report_every_nth_scrape = 10, # how chatty do you want to be
  number_of_tries = 3, # in case of connection time-outs
  # BigQuery settings
  project = "polynomial-coda-151914",
  bq_dataset = "mplaats_advs", # TO BE: "mplaats_ads"
  bq_table = "ads", # TO BE: "all_ads"
  bq_logs = "logs",
  batch_size = 100
)

log_items <- list(
  start_time = Sys.time()
)

# Initialize bigquery dataset
initialize_bigquery_dataset(project = settings$project, bq_dataset = settings$bq_dataset,bq_table = settings$bq_table)

# Get all open ads from google bigquery TODO
open_ads <- get_ads_from_bigquery(
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_table,
  method = "open"
)

# Get all currently listed ads from marktplaats
listed_ads <- list_advertisements(
  url = settings$search_url,
  advertisement_type = "individuals" #, max_pages = 5 
)

# Determine which ads to scrape, and scrape 'em!
scraped_ads <- determine_ads_to_scrape(
    listed = listed_ads$ad_id, 
    ads_seen = open_ads
  ) %>% 
  scrape_ads(
    ads_per_minute = settings$ads_per_minute,
    report_every_nth_scrape = settings$report_every_nth_scrape,
    number_of_tries = settings$number_of_tries
  )

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

log_items$end_time_uploading <- Sys.time()
log_items$duration_scraping <- log_items$end_time_scraping - log_items$start_time
log_items$duration_uploading <- log_items$end_time_uploading - log_items$end_time_scraping
log_items$total_time <- log_items$end_time_uploading - log_items$start_time

# report log print 
upload_log_to_bigquery(
  logs = log_items,
  project = settings$project,
  bq_dataset = settings$bq_dataset,
  bq_table = settings$bq_logs
)


