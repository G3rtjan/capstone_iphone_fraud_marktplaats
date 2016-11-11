
##
#### SETUP ####
##
# Clear workspace
rm(list=ls())

# Source scripts
source("../R/common.R")
source("../R/scrape_available_advs_overview.R")
source("../R/scrape_advs_details.R")
source("../R/scrape_advs_images.R")

# Specify packages to load
packages_for_data_munging <- c("data.table","dplyr","dtplyr","tidyr","lubridate","stringr")
packages_for_scraping <- c("rvest","XML")
# Combine all packages
packages_to_load <- c(packages_for_data_munging,packages_for_scraping)
# Load all packages
load_packages(
  packages_to_load = packages_to_load
)

# Define settings
settings <- list(
  # Define marktplaats url for iphone
  url_marktplaats_search = "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex",
  # Define css selectors for adv scraping wrapper
  css_price = "#vip-ad-price-container .price",
  css_view_count = "#view-count",
  css_favoured_count = "#favorited-count",
  css_displayed_since = "#displayed-since span:nth-child(3)",
  css_shipping_details = ".shipping-details-value:nth-child(2)",
  css_counterparty = ".top-info .name",
  css_cp_active_since = "#vip-active-since span",
  css_cp_location = "#vip-seller-location",
  css_attribute_names = "#vip-ad-attributes .name",
  css_attribute_values = "#vip-ad-attributes .value",
  css_description = "#vip-ad-description",
  css_bidder = "#vip-bids-top .ellipsis",
  css_bid_amount = ".bid-amount",
  css_bid_date = ".bid-date"
)


##
#### GET OVERVIEW OF ALL IPHONE ADVS FROM MARKTPLAATS ####
##
# Determine number of results pages
n_pages <- get_number_of_adv_pages(settings$url_marktplaats_search)
# Create vector of pages to crawl
page_urls <- paste0(settings$url_marktplaats_search,"&currentPage=",1:n_pages)
# Get advs from each page
advs_data <- lapply(X = page_urls,FUN = get_advs_overview_from_page)
advs_data <- do.call("rbind", advs_data)
# Remove dublicates and filter business advs
advs_data <- advs_data %>% 
  distinct(.keep_all = T) %>% 
  filter(grepl("m",adv_id)) %>% 
  arrange(desc(adv_id))


##
#### SCRAPE DETAILS FOR EACH ADV ####
##
# Wrapper function to get details from an adv on marktplaats
get_adv_details <- function(adv_url) {
  # Get html for the page
  adv_html <- adv_url %>% 
    read_html()
  # Only get add if still available
  if(check_adv_available(adv_html)) {
    # Get details and return
    data.frame(adv_url = adv_url) %>% 
      mutate(
        price = get_css_element(adv_html, settings$css_price),
        views = get_css_element(adv_html, settings$css_view_count, as_numeric = TRUE),
        favorites = get_css_element(adv_html, settings$css_favoured_count, as_numeric = TRUE),
        displayed_since = get_css_element(adv_html, settings$css_displayed_since),
        shipping = get_css_element(adv_html, settings$css_shipping_details),
        counterparty = get_css_element(adv_html, settings$css_counterparty),
        cp_n_of_advs = get_n_of_advs_of_counterparty(adv_html),
        cp_active_since  = get_css_element(adv_html, settings$css_cp_active_since),
        cp_location = get_css_element(adv_html, settings$css_cp_location, remove_chars = c("\n","  ")),
        biddings = list(
          data.frame (
            bidder = get_css_element(adv_html, settings$css_bidder, expecting_one = FALSE),
            bid = get_css_element(adv_html, settings$css_bid_amount, expecting_one = FALSE),
            bid_date = get_css_element(adv_html, settings$css_bid_date, expecting_one = FALSE)
          )
        ),
        attributes = list(
          data.frame (
            attribute = get_css_element(adv_html, settings$css_attribute_names, expecting_one = FALSE),
            value = get_css_element(adv_html, settings$css_attribute_values, expecting_one = FALSE)
          )
        ),
        description = get_css_element(adv_html, settings$css_description)
      ) %>% 
      return()
  }
}


##
#### ASSESS SCRIPT DURATION ####
##
# Determine number of pages to use
n <- 100

# Get advs from each page
time <- system.time({
  advs_details <- lapply(X = advs_data$url[1:n],FUN = get_adv_details)
  advs_details <- do.call("rbind", advs_details)
})
(time[3] / n)* dim(advs_data)[1] / 60 # minutes
# Scraping everything will take about 35 minutes
# Scraping only private ads will take about 25 minutes

# Get advs images from each page
time <- system.time({
  lapply(X = advs_data$url[1:n],FUN = get_adv_images, storage_dir="~/marktplaats_images")
})
(time[3] / n)* dim(advs_data)[1] / 60 # minutes
# Scraping everything will take about 44 minutes
# Scraping only private ads will take about 33 minutes




