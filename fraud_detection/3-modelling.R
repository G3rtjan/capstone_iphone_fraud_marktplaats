
##### First approach #### 
# weighed scoring of suspicious features

weighted_features_model <- function(data) {
  
  # clean 
  data <- data %>% 
    mutate(rel_price = 1 - rel_price) %>%  #because lower price is more suspicious
    mutate(has_phone_nbr = ifelse(has_phone_nbr, 1L, 0L)) %>% 
    mutate(rel_cp_age = 1 - rel_cp_age) # younger is more suspicious 
  
  preProcValues <- caret::preProcess(data, method = c("center", "scale")) 
  trainTransformed <- predict(preProcValues, data)
  
  trainTransformed %>%
    mutate(p = 1 * rel_price + 0.5 * has_phone_nbr + 
             1.2 * cp_n_of_advs + 1 * rel_cp_age + 
             1.2 * img_reuse)
}


weighted_features_model(training) %>% 
  arrange(desc(p))

# m1127811227
