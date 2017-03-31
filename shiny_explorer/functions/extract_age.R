extract_age <- function(x) {
  n <- as.numeric(gsub("\\D","",x))
  n <- ifelse(grepl("maanden|maand", x), n / 12, n)
  n <- ifelse(grepl("weken|week", x), n / 12, n)
  n <- ifelse(grepl("dagen|dag", x), n / 12, n)
  n
}

testthat::expect_equal(
  c("7 maanden", "11 jaar", "1 dag", "2 weken", "1 week") %>% extract_age(),
  c(0.58333333,11.00000000,0.08333333,0.16666667,0.08333333) 
)

# full_mp %>% 
#   filter(!grepl("jaren|jaar|maanden|maand|weken|week|dagen|dag", cp_active_since)) %>% 
#   select(cp_active_since)