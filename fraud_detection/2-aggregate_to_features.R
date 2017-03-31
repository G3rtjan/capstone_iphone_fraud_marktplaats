
#### Hypotheses/assumptions for Fraud ####

## Label for (potential) fraud:
# - merchant does not exist anymore (account has been removed)

## Filtering for fraud:
# - merchant is not a company
# - shipping method contains 'Verzenden'

## Features for fraud detection:
# - number of name changes of merchant
# - merchant account is younger than average merchant account
# - uniqueness of ad photos that are used
# - underpriced iphone
# - merchant has contact information (phone number)
# - ad description asks to contact by sms/whatsapp/email
# - average number of ads the merchants has open


#### SETUP ####

# NOTE: You need to set the working directory to the location of this script!

# Load packages
library(magrittr)

# Load local functions from /functions folder
purrr::walk(list.files("functions", full.names = T), source)


#### LOAD DATA ####

# Get all adds data
full_mp <- readRDS("../data/mpdata/full_mp_data.RData")

# Read aggregated ads data
agg_mp <- readRDS("../data/mpdata/agg_mp_data.RData")

# Read image hashes
hashes <- readRDS("../data/mpdata/image_hash_table.RData")
  

#### DATA TRANSFORMATION ####

# Clean several fields
full_mp <- full_mp %>% 
  dplyr::mutate(
    cp_age = extract_age(cp_active_since),
    price_value = extract_price(price),
    model_type = gsub("^\\s+|\\s+$", "", model)
  ) # you can ignore the warning :)

# Calculate mean price per iPhone model
model_prices <- full_mp %>% 
  dplyr::group_by(model_type) %>%
  dplyr::summarise(
    avg_price = mean(price_value, na.rm = T),
    n = n()
  ) %>% 
  dplyr::arrange(desc(n))

# Add mean price to the data
full_mp <- model_prices %>% 
  dplyr::select(model_type, avg_price) %>% 
  dplyr::left_join(
    x = full_mp,
    y = .,
    by = "model_type"
  )

# Add merchant id to image hash data
hashes <- full_mp %>% 
  dplyr::select(ad_id,cp_id) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::inner_join(hashes, by = "ad_id") %>% 
  dplyr::filter(!is.na(hash))


#### CREATE TRAINING DATA ####

# Create label of (potential) fraud
label_cp_is_removed <- full_mp %>% 
  dplyr::mutate(is_removed = ifelse(n_ads == "Removed", 1, 0)) %>% 
  dplyr::group_by(cp_id) %>% 
  dplyr::summarise(is_removed = max(is_removed)) %>% 
  dplyr::left_join(full_mp, by = "cp_id") %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarise(is_removed = max(is_removed))

# Create table with all ad_ids, applying filtering for fraud and adding label
training <- full_mp %>% 
  dplyr::mutate(
    is_company = grepl("kvk|koophandel|openingstijden", description, ignore.case = T),
    has_verzenden = grepl("verzenden", shipping, ignore.case = T)
  ) %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarise(
    is_company = max(is_company, na.rm = T),
    has_verzenden = max(has_verzenden, na.rm = T)
  ) %>% 
  # Merchant is not a company
  dplyr::filter(is_company == 0) %>% 
  # Shipping method contains 'Verzenden'
  dplyr::filter(has_verzenden == 1) %>% 
  # Get all remaining ad_ids for training
  dplyr::select(ad_id) %>% 
  # Add label of fraud
  dplyr::left_join(label_cp_is_removed, by = "ad_id") %>% 
  tidyr::replace_na(list(is_removed = 0))


#### FEATURE BUILDING ####

# Add feature about number of name changes of merchant
feature_cp_n_name_changes <- full_mp %>% 
  dplyr::group_by(cp_id) %>% 
  dplyr::summarise(cp_n_name_changes = n_distinct(counterparty)) %>% 
  dplyr::left_join(full_mp, by = "cp_id") %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarise(cp_n_name_changes = max(cp_n_name_changes) - 1) %>% 
  dplyr::mutate(cp_had_name_change = ifelse(cp_n_name_changes > 0, 1, 0))
training <- training %>% 
  dplyr::left_join(feature_cp_n_name_changes, by = "ad_id") %>% 
  tidyr::replace_na(list(cp_n_name_changes = 0, cp_had_name_change = 0))

# Add feature about merchant account youngness
feature_cp_youngness <- full_mp %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarize(cp_age = max(cp_age)) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(merchant_youngness = -scale(cp_age))
training <- training %>% 
  dplyr::left_join(feature_cp_youngness, by = "ad_id") %>% 
  dplyr::select(-cp_age) %>% 
  tidyr::replace_na(list(merchant_youngness = 0))

# Add feature about uniqueness of ad photos that are used
feature_img_reuse <- hashes %>% 
  dplyr::group_by(hash) %>% 
  dplyr::mutate(
    n_ads_with_same_image = length(unique(ad_id)),
    n_cps_with_same_image = length(unique(cp_id))
  ) %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarise(
    img_reuse_in_ads = max(n_ads_with_same_image) - 1,
    img_reuse_by_cps = max(n_cps_with_same_image) - 1
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(
    img_was_reused_in_ad = ifelse(img_reuse_in_ads > 0, 1, 0),
    img_was_reused_by_cp = ifelse(img_reuse_by_cps > 0, 1, 0)
  )
training <- training %>% 
  dplyr::left_join(feature_img_reuse, by = "ad_id") %>% 
  tidyr::replace_na(
    list(
      img_reuse_in_ads = 0, 
      img_was_reused_in_ad = 0,
      img_reuse_by_cps = 0,
      img_was_reused_by_cp = 0
    )
  )

# Add feature about underpiced iphone (determined per model)
feature_underpriced_iphone <- full_mp %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarise(
    highest_price = max(price_value,na.rm = T),
    avg_price = mean(avg_price,na.rm = T)
  ) %>% 
  dplyr::rowwise() %>% 
  dplyr::mutate(
    rel_price = highest_price / avg_price,
    underpricedness = ifelse(rel_price < 1, 1 - rel_price, 0)
  ) %>% 
  dplyr::select(ad_id,underpricedness)
training <- training %>% 
  dplyr::left_join(feature_underpriced_iphone, by = "ad_id") %>% 
  tidyr::replace_na(list(underpricedness = 0))

# Add feature about merchant has contact information (phone number)
feature_has_phone_nbr <- full_mp %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarize(has_phone_nbr = any(!is.na(cp_tel_number)))
training <- training %>% 
  dplyr::left_join(feature_has_phone_nbr, by = "ad_id") %>% 
  tidyr::replace_na(list(has_phone_nbr = 0))

# Add feature about average number of ads the merchant has open
feature_cp_n_of_advs <- full_mp %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarise(cp_n_of_advs = round(mean(cp_n_of_advs, na.rm = T),0))
training <- training %>% 
  dplyr::left_join(feature_cp_n_of_advs, by = "ad_id") %>% 
  tidyr::replace_na(list(cp_n_of_advs = 1))

# Add feature about ad description asks to contact by sms/whatsapp/email
features_text_based <- full_mp %>% 
  dplyr::select(ad_id,description) %>% 
  dplyr::distinct(.keep_all = T) %>% 
  dplyr::group_by(ad_id) %>% 
  dplyr::summarize(
    mentions_whatsapp = any(grepl("whatsapp", description, ignore.case = T)),
    mentions_sms = any(grepl("sms", description, ignore.case = T)),
    mentions_mail = any(grepl("mail", description, ignore.case = T)),
    mentions_bericht = any(grepl("bericht", description, ignore.case = T)),
    mentions_bellen = any(grepl("bellen", description, ignore.case = T)),
    mentions_contact = any(grepl("contact", description, ignore.case = T)),
    mentions_any = any(grepl("whatsapp|sms|mail|bericht|bellen|contact", description, ignore.case = T))
  )
training <- training %>% 
  dplyr::left_join(features_text_based, by = "ad_id") %>% 
  tidyr::replace_na(
    list(
      mentions_whatsapp = 0,
      mentions_sms = 0,
      mentions_mail = 0,
      mentions_bericht = 0,
      mentions_bellen = 0,
      mentions_contact = 0,
      mentions_any = 0
    )
  )


#### STORE TRAINING DATA ####
# Create model directory if not exist
if (!dir.exists("../data/model")) {
  dir.create("../data/model")
}

# Store training data
saveRDS(training, "../data/model/training_data.RData")


