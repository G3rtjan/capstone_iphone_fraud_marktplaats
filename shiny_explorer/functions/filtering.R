filter_cp <- function(all_ads, cp) {
  all_ads %>% 
    dplyr::filter(cp_id == cp) %>% 
    return()
}
filter_ad <- function(all_ads, ad) {
  all_ads %>% 
    dplyr::filter(ad_id == ad) %>% 
    return()
}