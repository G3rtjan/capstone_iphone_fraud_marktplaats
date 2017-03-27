extract_price <- function(price) {
  price %>% 
    gsub("[a-zA-Z]|.* ","",.) %>% 
    gsub(",",".",.) %>% 
    as.numeric() %>% 
    invisible() %>% 
    return()
}