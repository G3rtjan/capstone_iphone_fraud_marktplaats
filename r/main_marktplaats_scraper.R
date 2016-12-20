
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
  number_of_tries = 3 # in case of connection time-outs
)


# Get all open ads from google bigquery TODO
open_ads <- get_ads_from_bigquery(method = "open")

# Get all currently listed ads from marktplaats
listed_ads <- list_advertisements(
  url = settings$search_url,
  advertisement_type = "individuals"
  #max_pages = 5 
)

# Determine which ads to scrape, and scape 'em!
determine_ads_to_scrape(listed = listed_ads$ad_id, 
                        ads_seen = open_ads) %>% 
  scrape_ads(
    ads_per_minute = settings$ads_per_minute,
    report_every_nth_scrape = settings$report_every_nth_scrape,
    number_of_tries = settings$number_of_tries
  )



# Append it to gooogle bigquery


# report log print 
