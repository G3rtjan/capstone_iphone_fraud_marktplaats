
# SETUP
library(mpscraper) # If you do not use the docker container, install using devtools::install_github("timvink/mpscraper")

purrr::walk(list.files("/functions"), source)

# Awesome marktplaats scraper
settings <- list(
  search_url = "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex"
)


# Get all open ads from google bigquery TODO
bq_ads <- get_ads_from_bigquery(method = "open")


# Get all currently listed ads from marktplaats
ads <- list_advertisements(
  url = settings$search_url,
  advertisement_type = "individuals", 
  max_pages = 5 
)
print("remember to turn off max.pages = 5")

# combine.
determine_ads_to_

# Scrape it! 
all_ad_data <- scrape_ads(ads$adv_id)

# Append it. 

