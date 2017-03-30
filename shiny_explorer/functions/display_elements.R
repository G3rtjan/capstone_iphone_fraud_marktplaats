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