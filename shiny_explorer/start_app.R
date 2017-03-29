
# Dependencies
library(magrittr)
library(shinythemes)

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

# Read aggregated ads data
all_ads_info <- readRDS(file = "../data/mpdata/agg_mp_data.RData")

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


