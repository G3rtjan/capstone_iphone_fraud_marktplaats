collapse_unique <- function(values) {
  values %>% 
    unique() %>% 
    na.omit() %>% 
    paste0(collapse = " /&/ ") %>% 
    return()
}