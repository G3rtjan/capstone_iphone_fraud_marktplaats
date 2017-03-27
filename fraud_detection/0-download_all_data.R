
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
  bq_settings = "settings",
  # Location to store the data
  storage_dir = "C:/Accelerator/Capstone project/Data"
)


#### Download data ####
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
    storage_dir = settings$storage_dir,
    closed_ads = closed_ads[['ad_id']]
  )

# Combine all add data in single RData file
dir(path = settings$storage_dir, pattern = ".RData", full.names = T) %>% 
  purrr::map_df(readRDS) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  saveRDS(file = file.path(settings$storage_dir,"full_mp_data.RData"))


