
apply_fraud_model <- function(ad_id, scaling_model, fraud_model, model_prices, image_hashes, image_dir) {

  # Check for valid input
  if (!grepl("[mM|aA][0-9]{9}", ad_id)) return()
  
  #### SCRAPE AD INFO ####
  
  # Scrape ad_id
  data <- mpscraper::scrape_advertisement(ad_id) 
  
  # Add missing fields
  data <- data %>% 
    dplyr::mutate(
      condition = if (exists('condition', where = data)) condition else "",
      subscription = if (exists('subscription', where = data)) subscription else "",
      model = if (exists('model', where = data)) model else "",
      colour = if (exists('colour', where = data)) colour else "",
      simlock = if (exists('simlock', where = data)) simlock else ""
    )
  
  # Clean several fields
  data <- data %>% 
    dplyr::mutate(
      cp_age = extract_age(cp_active_since),
      price_value = extract_price(price),
      model_type = gsub("^\\s+|\\s+$", "", model)
    ) # you can ignore the warning :)
  
  # Add mean price to the data
  data <- model_prices %>% 
    dplyr::select(model_type, avg_price) %>% 
    dplyr::left_join(
      x = data,
      y = .,
      by = "model_type"
    )
  
  
  #### SCRAPE AD IMAGES
  
  # Download images
  mpscraper::scrape_adv_images(ad_id,image_dir)
  
  # Hash images
  i <<- 1
  ad_image_hash <- list.files(image_dir, pattern = ".jpg",full.names = T) %>% 
    purrr::map_df(hash_image) %>% 
    dplyr::mutate(
      ad_id = gsub("_.*","",image),
      image_nr = image %>% 
        gsub(".*_","",.) %>% 
        gsub("\\..*","",.) %>% 
        as.numeric()
    ) %>% 
    dplyr::arrange(ad_id,image_nr)

  # Add merchant id to image hash data
  ad_image_hash <- data %>% 
    dplyr::select(ad_id,cp_id) %>% 
    dplyr::distinct(.keep_all = T) %>% 
    dplyr::inner_join(ad_image_hash, by = "ad_id") %>% 
    dplyr::filter(!is.na(hash))
  
  # Add ad hashes to all hashes
  image_hashes <- dplyr::bind_rows(
    image_hashes %>% 
      dplyr::filter(
        ad_id %in% unique(ad_image_hash$ad_id) |
        cp_id %in% unique(ad_image_hash$cp_id) |
        hash %in% unique(ad_image_hash$hash)
      ),
    ad_image_hash
  )
  
  
  #### FEATURE BUILDING ####

  # Create prediction data
  prediction_data <- data %>%
    dplyr::select(ad_id)
  
  # Add feature about number of name changes of merchant
  feature_cp_n_name_changes <- data %>% 
    dplyr::group_by(cp_id) %>% 
    dplyr::summarise(cp_n_name_changes = n_distinct(counterparty)) %>% 
    dplyr::left_join(data, by = "cp_id") %>% 
    dplyr::group_by(ad_id) %>% 
    dplyr::summarise(cp_n_name_changes = max(cp_n_name_changes) - 1) %>% 
    dplyr::mutate(cp_had_name_change = ifelse(cp_n_name_changes > 0, 1, 0))
  prediction_data <- prediction_data %>% 
    dplyr::left_join(feature_cp_n_name_changes, by = "ad_id") %>% 
    tidyr::replace_na(list(cp_n_name_changes = 0, cp_had_name_change = 0))
  
  # Add feature about merchant account youngness
  feature_cp_youngness <- data %>% 
    dplyr::group_by(ad_id) %>% 
    dplyr::summarize(merchant_youngness = -max(cp_age))
  prediction_data <- prediction_data %>% 
    dplyr::left_join(feature_cp_youngness, by = "ad_id") %>% 
    tidyr::replace_na(list(merchant_youngness = 0))
  
  # Add feature about uniqueness of ad photos that are used
  feature_img_reuse <- image_hashes %>% 
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
  prediction_data <- prediction_data %>% 
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
  feature_underpriced_iphone <- data %>% 
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
  prediction_data <- prediction_data %>% 
    dplyr::left_join(feature_underpriced_iphone, by = "ad_id") %>% 
    tidyr::replace_na(list(underpricedness = 0))
  
  # Add feature about merchant has contact information (phone number)
  feature_has_phone_nbr <- data %>% 
    dplyr::group_by(ad_id) %>% 
    dplyr::summarize(has_phone_nbr = any(!is.na(cp_tel_number)))
  prediction_data <- prediction_data %>% 
    dplyr::left_join(feature_has_phone_nbr, by = "ad_id") %>% 
    tidyr::replace_na(list(has_phone_nbr = 0))
  
  # Add feature about average number of ads the merchant has open
  feature_cp_n_of_advs <- data %>% 
    dplyr::group_by(ad_id) %>% 
    dplyr::summarise(cp_n_of_advs = round(mean(cp_n_of_advs, na.rm = T),0))
  prediction_data <- prediction_data %>% 
    dplyr::left_join(feature_cp_n_of_advs, by = "ad_id") %>% 
    tidyr::replace_na(list(cp_n_of_advs = 1))
  
  # Add feature about ad description asks to contact by sms/whatsapp/email
  features_text_based <- data %>% 
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
  prediction_data <- prediction_data %>% 
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

  # Apply scaling model
  prediction_data_scaled <- predict(scaling_model, prediction_data)
  
  # Apply fraud model
  prediction <- predict(
    fraud_model, 
    prediction_data_scaled %>% 
      dplyr::select(-ad_id) %>% 
      data.matrix
  )
  
  # Return aggregate data with fraud score
  data %>% 
    dplyr::mutate(fraud_score = prediction) %>% 
    return()
  
}
