
#### DATA UPDATES ####

# Update ads information for table
scrape_ad_info <- reactive({
  if (grepl("[mM|aA][0-9]{9}", input$SNA_typed_ad_id)) {
    scraped_data <- apply_fraud_model(
      ad_id = input$SNA_typed_ad_id,
      scaling_model = global_vars$scaling_model,
      fraud_model = global_vars$fraud_model,
      model_prices = global_vars$model_prices,
      image_hashes = global_vars$image_hashes,
      image_dir = global_vars$image_dir
    )
    if (is.null(scraped_data)) {
      apply_fraud_model(
        ad_id = input$SNA_selected_ad,
        scaling_model = global_vars$scaling_model,
        fraud_model = global_vars$fraud_model,
        model_prices = global_vars$model_prices,
        image_hashes = global_vars$image_hashes,
        image_dir = global_vars$image_dir
      )
    } else {
      scraped_data
    }
  } else {
    apply_fraud_model(
      ad_id = input$SNA_selected_ad,
      scaling_model = global_vars$scaling_model,
      fraud_model = global_vars$fraud_model,
      model_prices = global_vars$model_prices,
      image_hashes = global_vars$image_hashes,
      image_dir = global_vars$image_dir
    )
  }
})

# Update list of images
update_new_ad_images <- reactive({
  scraped_data <- scrape_ad_info()
  dir(
      path = global_vars$image_dir,
      full.names = T
    ) %>% 
    tibble::tibble(file_path = .) %>%
    dplyr::mutate(
      file_path = file_path,
      ad_id = basename(file_path) %>% 
        gsub("_.*","",.),
      image_nr = basename(file_path) %>% 
        gsub(".*_","",.) %>% 
        gsub("\\..*","",.) %>% 
        as.numeric()
    ) %>% 
    dplyr::arrange(ad_id,image_nr) %>% 
    dplyr::filter(ad_id %in% c(scraped_data$ad_id))
})


#### INPUT UPDATES ####

# Update choices for SNA_selected_ad
# observe({
#   updateSelectizeInput(
#     session = session,
#     inputId = "SNA_selected_ad",
#     choices = global_vars$new_ads,
#     server = TRUE
#   )
# })

# Render UI with list of ad_images
output$SNA_UI_select_ad_image <- renderUI({
  images <- update_new_ad_images()
  if (nrow(images) > 0) {
    fluidRow(
      sliderInput(
        inputId = "SNA_select_ad_image",
        label = "Select image",
        min = min(images$image_nr),
        max = max(images$image_nr),
        value = min(images$image_nr),
        step = 1,
        pre = "Nr. "
      ),
      style = "margin-left:10px; margin-right:10px"
    )
  } else {
    fluidRow()
  }
})

# Render image based on slider
output$SNA_ad_image <- renderImage({
    image <- update_new_ad_images() %>%
      dplyr::filter(image_nr %in% c(input$SNA_select_ad_image)) %>%
      .[['file_path']]
    if (length(image) == 1) {
      list(
          src = image,
          width = "250px",
          heigth = "250px"
        ) %>%
        return()
    } else {
      list(
          src = "http://marktplaatsperskamer.nl/wp-content/uploads/2016/04/marktplaatslogo.jpg", #"placeholder.jpg",
          width = "250px",
          heigth = "50px"
        ) %>%
        return()
    }
  },
  deleteFile = F
)


#### RESET BUTTONS ####

# Observe event of pressing reset button
observeEvent(
  eventExpr = input$SNA_reset_all,
  handlerExpr = {
    # Progress message
    withProgress(message = 'Resetting, please wait...', value = 0.5, {
      
      # Update selected for SNA_selected_ad
      updateSelectizeInput(
        session = session,
        inputId = "SNA_selected_ad",
        choices = global_vars$new_ads,
        selected = "",
        server = TRUE
      )
      
      # Update selected for SNA_selected_ad
      updateTextInput(
        session = session,
        inputId = "SNA_typed_ad_id",
        value = ""
      )
      
      # Progress finished
      setProgress(1)
    })
  }
)

# Observe event of pressing random pick button
observeEvent(
  eventExpr = input$SNA_random_pick,
  handlerExpr = {
    # Random pick a merchant
    random_pick <- sample(
      x = global_vars$new_ads,
      size = 1
    )
    # Update selected for SNA_selected_ad
    updateSelectizeInput(
      session = session,
      inputId = "SNA_selected_ad",
      choices = random_pick
    )
  }
)


#### OUTPUT UPDATES ####

# Create table with general ad info
output$SNA_ad_general_info <- renderTable(
  expr = display_elements(
    ads_info = scrape_ad_info(),
    elements = c(
      "title",
      "ad_id",
      "views",
      "favorites",
      "displayed_since",
      "counterparty",
      "cp_id"
    ),
    header = "General info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad product info
output$SNA_ad_product_info <- renderTable(
  expr = display_elements(
    ads_info = scrape_ad_info(),
    elements = c(
      "condition",
      "subscription",
      "model",
      "colour",
      "simlock"
    ),
    header = "Product info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad description
output$SNA_ad_description <- renderTable(
  expr = scrape_ad_info() %>% 
    dplyr::select(description) %>% 
    dplyr::rename(Description = description),
  spacing = "m",
  align = "l",
  width = "100%"
)

# Create table with fraud score
output$SNA_fraud_score <- renderTable(
  expr = display_elements(
    ads_info = scrape_ad_info() %>% 
      dplyr::mutate(fraud_score = paste(round(fraud_score * 100,2),"%")),
    elements = c("fraud_score"),
    header = "Fraud detection"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad price info
output$SNA_ad_price_info <- renderTable(
  expr = display_elements(
    ads_info = scrape_ad_info(),
    elements = c(
      "price",
      "shipping",
      "shipping_costs"
    ),
    header = "Sale info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad bidding info
output$SNA_ad_bidding_info <- renderTable(
  expr = display_elements(
    ads_info = scrape_ad_info(),
    elements = c(
      "biddings_active",
      "biddings_n",
      "biddings_lowest_bid",
      "biddings_highest_bid",
      "biddings_unique_bidders"
    ),
    in_euro = c(
      "biddings_lowest_bid",
      "biddings_highest_bid"
    ),
    header = "Bidding info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)
