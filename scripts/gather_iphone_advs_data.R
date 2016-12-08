
##
#### SETUP ####
##

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
library(mpscraper) # Install from https://github.com/timvink/mpscraper



##
#### GET OVERVIEW OF ALL IPHONE ADVS FROM MARKTPLAATS ####
##
# Determine number of results pages


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




