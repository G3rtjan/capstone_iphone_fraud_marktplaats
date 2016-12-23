# Function to determine the total list of ads to scrape, based on listed new
# adds (listed) and open adds in big query (open_ads)
determine_ads_to_scrape <- function(ads_listed, ads_seen) {
  
  ads_not_yet_seen <- purrr::discard(ads_listed, ~ .x %in% ads_seen)
  
  return(unique(c(ads_not_yet_seen, ads_seen)))
  
}
