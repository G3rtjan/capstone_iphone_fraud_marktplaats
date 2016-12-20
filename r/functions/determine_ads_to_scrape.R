# Function to determine the total list of ads to scrape, based on listed new
# adds (listed) and open adds in big query (open_ads)
determine_ads_to_scrape <- function(listed, open_ads) {
  listed %>% 
    dplyr::filter(!adv_id %in% unique(big_query_ads$adv_id)) %>% 
    dplyr::select(adv_id) %>% 
    dplyr::union(x = ., y = open_ads) %>% 
    dplyr::arrange(adv_id) %>% 
    return()
}
