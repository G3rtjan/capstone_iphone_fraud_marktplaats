
#### DATA UPDATES ####

# Update available ads for a specific merchant
filter_ads_for_merchant <- reactive({
  filter_cp(
    all_ads = global_vars$ads_overview,
    cp = input$IAV_selected_merchant_or_ad
  )
})

# Update ads information for table
update_ads_data_info <- reactive({
  global_vars$all_ads_info %>% 
    dplyr::filter(ad_id %in% c(input$IAV_selected_merchant_or_ad,input$IAV_selected_ad))
})

# Update ads information for table
update_ads_text <- reactive({
  global_vars$all_ads_texts %>% 
    dplyr::filter(ad_id %in% c(input$IAV_selected_merchant_or_ad,input$IAV_selected_ad))
})

# Update list of images
update_ad_images <- reactive({
  global_vars$all_images %>% 
    dplyr::filter(ad_id %in% c(input$IAV_selected_merchant_or_ad,input$IAV_selected_ad))
})


#### INPUT UPDATES ####

# Update choices for IAV_selected_merchant_or_ad
observe({
  updateSelectizeInput(
    session = session,
    inputId = "IAV_selected_merchant_or_ad",
    choices = global_vars$selectizers,
    server = TRUE
  )
})

# Render UI for IAV_selected_ad if a merchant is selected
output$IAV_UI_select_ad <- renderUI({
  if (input$IAV_selected_merchant_or_ad != '' & !input$IAV_selected_merchant_or_ad %in% global_vars$ads) {
    fluidRow(
      selectizeInput(
        inputId = "IAV_selected_ad",
        label = "Select advertisement",
        choices = filter_ads_for_merchant()$ad_id,
        options = list(maxOptions = 100, placeholder = 'Start typing or click here')
      ),
      style = "margin-left:10px; margin-right:10px"
    )
  } else {
    fluidRow()
  }
})

# Render UI with list of ad_images
output$IAV_UI_select_ad_image <- renderUI({
  images <- update_ad_images()
  if (nrow(images) > 0) {
    fluidRow(
      sliderInput(
        inputId = "IAV_select_ad_image",
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
output$IAV_ad_image <- renderImage({
    image <- update_ad_images() %>%
      dplyr::filter(image_nr %in% c(input$IAV_select_ad_image)) %>%
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
  eventExpr = input$IAV_reset_all,
  handlerExpr = {
    # Progress message
    withProgress(message = 'Resetting, please wait...', value = 0.5, {
      
      # Update selected for IAV_selected_merchant_or_ad
      updateSelectizeInput(
        session = session,
        inputId = "IAV_selected_merchant_or_ad",
        choices = global_vars$selectizers,
        selected = "",
        server = TRUE
      )
      
      # Update progress
      incProgress(amount = 0.25)
      
      # Update selected for IAV_selected_ad
      updateSelectizeInput(
        session = session,
        inputId = "IAV_selected_ad",
        selected = ""
      )
      
      # Progress finished
      setProgress(1)
    })
  }
)

# Observe event of pressing random pick button
observeEvent(
  eventExpr = input$IAV_random_pick,
  handlerExpr = {
    # Random pick a merchant
    random_pick <- sample(
      x = global_vars$merchants,
      size = 1
    )
    # Update selected for IAV_selected_merchant_or_ad
    updateSelectizeInput(
      session = session,
      inputId = "IAV_selected_merchant_or_ad",
      choices = random_pick
    )
  }
)


#### OUTPUT UPDATES ####

# Create table with general ad info
output$IAV_ad_general_info <- renderTable(
  expr = display_elements(
    ads_info = update_ads_data_info(),
    elements = c(
      "title",
      "ad_id",
      "number_of_views",
      "number_of_favorites",
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
output$IAV_ad_product_info <- renderTable(
  expr = display_elements(
    ads_info = update_ads_data_info(),
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
output$IAV_ad_description <- renderTable(
  expr = update_ads_text() %>% 
    dplyr::select(description,from,to) %>% 
    dplyr::rename(
      Description = description,
      From = from,
      To = to
    ),
  spacing = "m",
  align = "lcc",
  width = "100%"
)

# Create table with ad price info
output$IAV_ad_price_info <- renderTable(
  expr = display_elements(
    ads_info = update_ads_data_info(),
    elements = c(
      "sales_method",
      "lowest_price",
      "highest_price"
    ),
    in_euro = c(
      "lowest_price",
      "highest_price"
    ),
    header = "Sale info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad shipping info
output$IAV_ad_shipping_info <- renderTable(
  expr = display_elements(
    ads_info = update_ads_data_info(),
    elements = c(
      "shipping_method",
      "shipping_costs"
    ),
    in_euro = c(
      "shipping_costs"
    ),
    header = "Shipping info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad bidding info
output$IAV_ad_bidding_info <- renderTable(
  expr = display_elements(
    ads_info = update_ads_data_info(),
    elements = c(
      "number_of_biddings",
      "number_of_unique_bidders",
      "minimum_lowest_bid",
      "maximum_lowest_bid",
      "minimum_highest_bid",
      "maximum_highest_bid"
    ),
    in_euro = c(
      "minimum_lowest_bid",
      "maximum_lowest_bid",
      "minimum_highest_bid",
      "maximum_highest_bid"
    ),
    header = "Bidding info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)

# Create table with ad scraping info
output$IAV_ad_scraping_info <- renderTable(
  expr = display_elements(
    ads_info = update_ads_data_info(),
    elements = c(
      "number_of_times_retrieved",
      "first_time_retrieved",
      "last_time_retrieved",
      "days_ad_was_followed"
    ),
    header = "Scraping info"
  ),
  spacing = "m",
  align = "lc",
  width = "100%"
)
