
# Dependencies
library(magrittr)

#### HELPER FUNCTIONS ####

extract_price <- function(price) {
  price %>% 
    gsub("[a-zA-Z]|.* ","",.) %>% 
    gsub(",",".",.) %>% 
    as.numeric() %>% 
    invisible() %>% 
    return()
}
collapse_unique <- function(values) {
  values %>% 
    unique() %>% 
    na.omit() %>% 
    paste0(collapse = " /&/ ") %>% 
    return()
}
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
display_elements <- function(ads_info, elements = c(), in_euro = c(), header = "element") {
  format_as_euro <- scales::dollar_format(prefix = "") # EURO: prefix = "\u20ac "
  ads_info %>% 
    dplyr::select_(.dots = elements) %>% 
    tidyr::gather("element","value",convert = T) %>% 
    dplyr::rowwise() %>% 
    dplyr::mutate(
      value = as.character(ifelse(element %in% in_euro & !is.na(value), paste(format_as_euro(as.numeric(value)),"euro"), value)),
      value = ifelse(is.na(value), "", value),
      element = gsub("_"," ",element)
    ) %>% 
    dplyr::rename_(.dots = setNames(c("element","value"), c(header," "))) %>% 
    dplyr::ungroup() %>% 
    return()
}


#### LOAD AND TRANSFORM DATA ####

# Get all adds data
all_ads <- readRDS("../data/mpdata/full_mp_data.RData") %>% 
  dplyr::filter(!is.na(ad_id) & !is.na(cp_id) & !is.na(displayed_since))

# List all images
all_images <- dir(
      path = "../data/mpimages",
    full.names = T
  ) %>% 
  tibble::tibble(file_path = .) %>%
  dplyr::mutate(
    ad_id = basename(file_path) %>% 
      gsub("_.*","",.),
    image_nr = basename(file_path) %>% 
      gsub(".*_","",.) %>% 
      gsub("\\..*","",.) %>% 
      as.numeric()
  )

# Get all ad texts
all_ads_texts <- all_ads %>%
  dplyr::select(cp_id,ad_id,description,time_retrieved) %>%
  dplyr::group_by(cp_id,ad_id,description) %>% 
  dplyr::summarise(
    from = min(time_retrieved, na.rm = T),
    to = max(time_retrieved, na.rm = T)
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::arrange(cp_id,ad_id,from) %>% 
  # Fixate date formats
  dplyr::mutate(
    from = as.character(from),
    to = as.character(to)
  )

# Aggregate ad information
agg_data_file <- "../data/mpdata/agg_mp_data.RData"
if (file.exists(agg_data_file)) {
  # Read from last time
  all_ads_info <- readRDS(agg_data_file)
} else {
  # Aggregate ads data into single row per ad
  all_ads_info <- all_ads %>%
    dplyr::mutate(
      price_value = extract_price(price),
      has_price = !is.na(price_value),
      sales_method = ifelse(has_price,NA,price),
      shipping_costs_value = extract_price(shipping_costs)
    ) %>% 
    dplyr::group_by(cp_id,ad_id,displayed_since) %>% 
    dplyr::summarize(
      # Collapse changes in title/merchant name
      title = collapse_unique(title),
      counterparty = collapse_unique(counterparty),
      # Aggregate price info
      sales_method = collapse_unique(sales_method),
      has_price = any(has_price),
      lowest_price = min(price_value,na.rm = T),
      highest_price = max(price_value,na.rm = T),
      price_has_changed = (lowest_price != highest_price),
      shipping_method = collapse_unique(shipping),
      shipping_costs = max(shipping_costs_value, na.rm = T),
      # Aggregate retrieval information
      number_of_times_retrieved = length(unique(time_retrieved)),
      first_time_retrieved = min(time_retrieved,na.rm = T),
      last_time_retrieved = max(time_retrieved,na.rm = T),
      days_ad_was_followed = floor((last_time_retrieved - first_time_retrieved)/(60*60*24)),
      # Aggregate bid information
      biddings_active = any(biddings_active),
      number_of_biddings = max(0, biddings_n, na.rm = T),
      number_of_unique_bidders = max(0, biddings_unique_bidders, na.rm = T),
      minimum_highest_bid = min(biddings_highest_bid, na.rm = T),
      maximum_highest_bid = max(biddings_highest_bid, na.rm = T),
      minimum_lowest_bid = min(biddings_lowest_bid, na.rm = T),
      maximum_lowest_bid = max(biddings_lowest_bid, na.rm = T),
      # Aggregate iPhone characteristics
      condition = collapse_unique(conditie),
      subscription = collapse_unique(abonnement),
      model = collapse_unique(model),
      colour = collapse_unique(kleur),
      simlock = collapse_unique(simlock),
      must_be_sold_quickly = any(moet_nu_weg == "Moet nu weg"),
      # Other info
      closed = max(closed, na.rm = T),
      number_of_views = max(views, na.rm = T),
      number_of_favorites = max(favorites, na.rm = T),
      was_reserved = any(reserved == "Gereserveerd"),
      number_of_photos = max(0, number_of_photos, na.rm = T)
    ) %>% 
    dplyr::ungroup() %>%
    # Fixate date formats
    dplyr::mutate(
      first_time_retrieved = as.character(first_time_retrieved),
      last_time_retrieved = as.character(last_time_retrieved)
    )
  # Save for quick loading next time
  saveRDS(all_ads_info, agg_data_file)
}

# Create overview of ads
ads_overview <- all_ads_info %>% 
  dplyr::select(ad_id,counterparty,cp_id) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::group_by(cp_id) %>% 
  dplyr::mutate(counterparty = collapse_unique(counterparty)) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(cp_info = paste0(counterparty," - (",cp_id,")")) %>% 
  dplyr::arrange(cp_info,ad_id)

# Create overview of all merchants and ads
merchants <- setNames(object = ads_overview$cp_id,nm = ads_overview$cp_info)
ads <- setNames(object = ads_overview$ad_id,nm = ads_overview$ad_id)


#### START APP ####

# Create global variables for Shiny app
global_vars <- list(
  all_images = all_images,
  all_ads_texts = all_ads_texts,
  all_ads_info = all_ads_info,
  ads_overview = ads_overview,
  merchants = merchants,
  ads = ads,
  selectizers = c(merchants,ads)
)

# Run the app
shiny::runApp(getwd(),launch.browser = T)


