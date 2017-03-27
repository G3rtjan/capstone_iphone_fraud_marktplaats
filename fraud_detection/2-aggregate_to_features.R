
library(tidyverse)
source("functions/extract_price.R")
source("functions/extract_age.R")

# Load
agg_mp <- readRDS("../data/mpdata/agg_mp_data.RData")
full_mp <- readRDS("../data/mpdata/full_mp_data.RData")
full_mp <- tibble::as_tibble(full_mp)
hashes <- readRDS("../data/mpdata/image_hash_table.RData")
removed_merchants <- readRDS("../data/mpdata/removed_merchants.RData")

# Cleaning
agg_mp <- agg_mp %>% 
  dplyr::mutate(model = iconv(model, from = "latin1", to = "ASCII", ""),
                model = gsub("Overige typen /&/", "", model))

full_mp <- full_mp %>% 
  dplyr::mutate(cp_age = extract_age(cp_active_since))

# Hypothesis for Fraud: 
# - underpriced
# - more than 2 iphones ads merchant
# - uses ad fotos that are used alot.
# - merchant is younger than average merchant
# - merchant does not exist anymore
training <- agg_mp %>% select(ad_id)

# underpriced. 
## Now relative to average price. Can be improved, f.e. xgboost model. 
model_prices <- agg_mp %>% 
  group_by(model) %>%
  summarise(avg_price = mean(highest_price, na.rm = T),
            n = n()) %>% 
  arrange(desc(n))
  
feature_pricing <- agg_mp %>% 
  select(ad_id, model, highest_price) %>% 
  left_join(model_prices, by = c("model")) %>% 
  mutate(rel_price = highest_price / avg_price) %>% 
  select(-n, -model, -avg_price, -highest_price)

training <- left_join(training, feature_pricing, by = "ad_id")
  
# phone number list in ad description? 
feature_phone_nbr <- full_mp %>% 
  group_by(ad_id) %>% 
  summarize(has_phone_nbr = any(!is.na(cp_tel_number)))
training <- left_join(training, feature_phone_nbr, by = "ad_id")
  
# Number of ads of merchant ?
feature_n_ads <- full_mp %>% 
  group_by(ad_id) %>% 
  summarise(cp_n_of_advs = max(cp_n_of_advs))
training <- left_join(training, feature_n_ads, by = "ad_id")

# relative age of merchant ?
full_mp %>% 
  group_by(cp_id) %>% 
  summarize(cp_age = max(cp_age)) %>% 
  ungroup() %>% 
  summarize(mean(cp_age))
feature_cp_age <- full_mp %>% 
  group_by(ad_id) %>% 
  summarize(rel_cp_age = max(cp_age) / 5.61109)
training <- left_join(training, feature_cp_age, by = "ad_id")

# uniqueness of ad photos? 
hashes %>% 
  group_by(hash) %>% 
  summarise(n_ads_same = n_distinct(ad_id)) %>% 
  arrange(desc(n_ads_same))
  
hashes %>% 
  dplyr::filter(hash == "552ec1c06bf2379c")


