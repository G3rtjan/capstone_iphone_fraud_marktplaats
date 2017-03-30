
##### First approach #### 
# weighed scoring of suspicious features

weighted_features_model <- function(data) {
  
  data %>%
    mutate(score = 1 * underpricedness + 0.5 * has_phone_nbr + 
             2 * cp_n_of_advs + 3 * cp_n_name_changes + 
             2 * img_reuse + 1 * mentions_contactdetails +
             4 * is_removed)
}

# manual check: sucks! 
weighted_features_model(train_scaled) %>% 
  arrange(desc(score)) %>% View

weighted_features_model(train_scaled) %>% 
  filter(is_removed == 1) %>% 
  arrange(desc(score)) %>% View


#### ML model approach #### 

library(xgboost)
xgboost::xgb.train()

train_scaled <- train_scaled %>% 
  filter(mentions_company == 0)

xg_model <- xgboost(data = train_scaled %>% select(-ad_id, -is_removed) %>% data.matrix(), 
                     label = train_scaled %>% select(is_removed) %>% data.matrix, 
                     max.depth = 3, eta = 1, nthread = 3, nround = 10, 
                     objective = "binary:logistic")
  
pred <- predict(xg_model,  train_scaled %>% select(-ad_id, -is_removed)%>% data.matrix())

result <- train_scaled %>% mutate(p = pred)
result %>% 
  arrange(desc(p)) %>% View

importance_matrix <- xgb.importance(model = xg_model)
print(importance_matrix)
xgb.plot.importance(importance_matrix = importance_matrix)

# size of the prediction vector
print(length(pred))
