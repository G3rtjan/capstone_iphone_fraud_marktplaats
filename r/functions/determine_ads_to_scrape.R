
# Function to determine the total list of ads to scrape, based on listed new adds (listed) and open adds in big query (open_ads)
determine_ads_to_scrape <- function(ads_listed, ads_seen, scrape_interval_h = numeric(), max_n = Inf) {

  # Filter listed ads that have already been seen
  ads_not_yet_seen <- purrr::discard(ads_listed$ad_id, ~ .x %in% ads_seen$ad_id)
  
  # Determine filtering based on scrape interval
  ads_seen_to_scrape <- ads_seen %>%
    dplyr::mutate(time_since_last_scrape = difftime(Sys.time(),last_scrape,units="hours")) %>% 
    dplyr::filter(time_since_last_scrape >= scrape_interval_h) %>% 
    dplyr::arrange(-time_since_last_scrape)
  
  # Combine all ads
  ads_to_scrape <- unique(c(ads_not_yet_seen, ads_seen_to_scrape$ad_id))
  
  # Return ads up to max_n
  if(length(ads_to_scrape) > max_n) {
    return(ads_to_scrape[1:max_n])
  } else {
    return(ads_to_scrape)
  }
}
