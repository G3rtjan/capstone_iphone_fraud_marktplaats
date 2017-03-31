
#### SETUP ####

# NOTE: You need to set the working directory to the location of this script!

# Load packages
library(magrittr)
library(caret)
library(xgboost)

# Load local functions from /functions folder
purrr::walk(list.files("functions", full.names = T), source)


#### FEATURE SCALING ####

# Load training data
training <- readRDS("../data/model/training_data.RData")

# Create scaling model (for non-binary features)
pre_proc_scaling_model <- training %>% 
  dplyr::select(
    ad_id,
    cp_n_name_changes,
    merchant_youngness,
    img_reuse_in_ads,
    img_reuse_by_cps,
    cp_n_of_advs
  ) %>%  
  caret::preProcess(method = c("center", "scale")) 

# Store scaling model
readr::write_rds(pre_proc_scaling_model, "../data/model/pre_proc_scaling_model.RData")

# Apply scaling model
training_scaled <- predict(pre_proc_scaling_model, training) %>% 
  dplyr::arrange(ad_id)

# Create an empty result table with unscaled features
result <- training %>% 
  dplyr::arrange(ad_id)


##### FIRST MODELLING APPROACH #### 

# Weighted scoring of suspicious features
weighted_features_model <- function(data) {
  data %>%
    dplyr::mutate(fraud_score = 
      5 * is_removed +
      2 * cp_n_name_changes +
      1 * merchant_youngness +
      1 * img_reuse_in_ads +
      3 * img_reuse_by_cps +
      0.5 * underpricedness + 
      0.5 * has_phone_nbr + 
      -0.5 * cp_n_of_advs + 
      4 * mentions_whatsapp +
      3 * mentions_sms +
      0.5 * mentions_mail +
      1 * mentions_bericht + 
      0.5 * mentions_bellen + 
      0.5 * mentions_contact
    ) %>%
    dplyr::arrange(desc(fraud_score)) %>% 
    return()
}

# Manual checks in MIFE app: seems to be quite nice already 
weighted_features_model(training_scaled) %>% View
# Potential frauds (similar ads, different counterparties)
# m1127600525, CP = DII
# m1129358913, CP = Willem

# Even when looking specifically at removed merchants
weighted_features_model(training_scaled) %>% 
  dplyr::filter(is_removed == 1) %>% 
  dplyr::arrange(desc(fraud_score)) %>% View
# OMG, same ads as above but again from different (and removed) counterparties
# m1133266935 # Handelaarsbloed
# m1133286401 # Willem


#### ML MODEL APPROACH, ATTEMPT 1 #### 

# Create xgboost model with all features
xgb_model_all_features <- xgboost::xgboost(
  data = training_scaled %>% 
            dplyr::select(-ad_id, -is_removed) %>% 
            data.matrix, 
  label = training_scaled %>% 
            dplyr::select(is_removed) %>% 
            data.matrix, 
  max.depth = 3, eta = 1, nthread = 3, nround = 10, objective = "binary:logistic"
)

# Apply model
predictions <- predict(
  xgb_model_all_features, 
  training_scaled %>% 
    dplyr::select(-ad_id, -is_removed) %>% 
    data.matrix
)

# Add predictions to result data
result <- result %>% 
  dplyr::mutate(fraud_p_1 = predictions)

# Manual checks in MIFE app: top fraud scoring ads could be fraud!
result %>%
  dplyr::arrange(desc(fraud_p_1)) %>% 
  View

# OMG, AGAIN same ads as above but again from different (and removed) counterparties
# m1120475099 CP = Rinus
# m1127628316 CP = Dii

# Different ad description, but again multiple ads from different (and removed) counterparties
# m1125841178 CP = Suzanne
# m1125925207 CP = Marijke
# m1127181667 CP = Familie Ter Aar

# Look at the feature importance
xgboost::xgb.importance(
  feature_names = training_scaled %>% 
    dplyr::select(-ad_id, -is_removed) %>% 
    colnames(),
    model = xgb_model_all_features
  ) %>% 
  xgboost::xgb.plot.importance()


#### ML MODEL APPROACH, ATTEMPT 2 #### 

# The feature merchant_youngness seems to be very important
# But, it might also be that there are just a lot of merchants who create 
# an account to sell something once and then remove their account,
# so let's try to build a model without this feature

# Create xgboost model with all features
xgb_model_limited_features <- xgboost::xgboost(
  data = training_scaled %>% 
            dplyr::select(-ad_id, -is_removed, -merchant_youngness) %>% 
            data.matrix, 
  label = training_scaled %>% 
            dplyr::select(is_removed) %>% 
            data.matrix, 
  max.depth = 3, eta = 1, nthread = 3, nround = 10, objective = "binary:logistic"
)

# Apply model
predictions <- predict(
  xgb_model_limited_features, 
  training_scaled %>% 
    dplyr::select(-ad_id, -is_removed, -merchant_youngness) %>% 
    data.matrix
)

# Add predictions to result data
result <- result %>% 
  dplyr::mutate(fraud_p_2 = predictions)

# Manual checks in MIFE app: doesn't seem to work as well as the first attempt
result %>%
  dplyr::arrange(desc(fraud_p_2)) %>% 
  View

# Look at the feature importance
xgboost::xgb.importance(
  feature_names = training_scaled %>% 
    dplyr::select(-ad_id, -is_removed, -merchant_youngness) %>% 
    colnames(),
    model = xgb_model_limited_features
  ) %>% 
  xgboost::xgb.plot.importance()


#### SAVE BEST MODEL ####

# Saving the model with all features
readr::write_rds(xgb_model_all_features, "../data/model/fraud_detection_model.RData")


#### CONCLUSIONS ####

## It seems fraud does occur on marktplaats and it can be detected by looking at:
# merchant_youngness (how long has the account been in existance)
# cp_n_of_advs (the number of advertisements of a merchant)
# img_reuse_in_ads (how often are the images in the ad reused in other ads)
# img_reuse_by_cps (how often are the images in the ad resued by other merchants)
# has_phone_nbr (is there a phone number available to contact the merchant)
# underpricedness (is the prices for the iPhone lower than the mean price for that model on Marktplaats)e
# mentions_bericht (does the ad ask buyers to send a message (usually outside of Marktplaats))
# cp_n_name_changes (how often has the name of the merchant been changed (though the id stays the same))
# mentions_whatsapp (does the ad ask buyers to send a message through WhatsApp)

# Another interesting fact is that it seems that when a fraudulant merchant is changing
# its name on Marktplaats, typical Dutch names are picked (which probably should give
# a sense of trustworthiness), like:
# Dik, Willem, Rinus
# Suzanne, Marijke, Familie Ter Aar


