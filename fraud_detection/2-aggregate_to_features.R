
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
  mutate(underpricedness = ifelse(rel_price < 1, 1 - rel_price, 0)) %>% 
  select(-n, -model, -avg_price, -highest_price, -rel_price)

training <- training %>% 
  left_join(feature_pricing, by = "ad_id") %>% 
  tidyr::replace_na(list(underpricedness = 0))

# phone number list in ad description? 
feature_phone_nbr <- full_mp %>% 
  group_by(ad_id) %>% 
  summarize(has_phone_nbr = any(!is.na(cp_tel_number)))
training <- training %>% 
  left_join(feature_phone_nbr, by = "ad_id") %>% 
  mutate(has_phone_nbr = if_else(is.na(has_phone_nbr) | has_phone_nbr == F, 0L, 1L))

# Number of ads of merchant ?
feature_n_ads <- full_mp %>% 
  group_by(ad_id) %>% 
  summarise(cp_n_of_advs = max(cp_n_of_advs))
training <- training %>% 
  left_join(feature_n_ads, by = "ad_id") %>% 
  tidyr::replace_na(list(cp_n_of_advs = 1))

# relative age of merchant ?
feature_cp_age <- full_mp %>% 
  group_by(ad_id) %>% 
  summarize(cp_age = max(cp_age)) %>% 
  ungroup() %>% 
  mutate(rel_cp_age = scale(cp_age)) %>% 
  mutate(merchant_youngness = -1 * rel_cp_age)
training <- training %>% 
  left_join(feature_cp_age, by = "ad_id") %>% 
  select(-cp_age, -rel_cp_age) %>% 
  tidyr::replace_na(list(merchant_youngness = 0))

# uniqueness of ad photos? 
feature_img_reuse <- hashes %>% 
  dplyr::filter(!is.na(hash)) %>% 
  group_by(ad_id) %>% 
  summarise(img_reuse = min(n_ads_with_same_image)) %>% 
  ungroup() %>% 
  mutate(img_reuse = log(img_reuse))
training <- training %>% 
  left_join(feature_img_reuse, by = "ad_id") %>% 
  mutate(img_reuse = tidyr::replace_na(list(img_reuse = 0)))

training

# scaling
pre_proc_scaling_model <- caret::preProcess(training, method = c("center", "scale")) 
readr::write_rds(pre_proc_scaling_model, "../data/model/pre_proc_scaling_model.RData")
train_scaled <- predict(pre_proc_scaling_model, training)

train_scaled

