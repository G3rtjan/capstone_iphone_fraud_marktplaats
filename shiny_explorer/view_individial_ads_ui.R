
# Create page with widgets
fluidPage(
  # Create page with a sidebar
  sidebarLayout(
    
    # Define the elements in the sidebar
    sidebarPanel(
      # Define width of the panel
      width = 3,
      
      # Create box with selectInputs
      fluidRow(
        column(
          width = 12,
          
          # Row with buttons
          fluidRow(
            column(
              width = 4,
              # Button to reset all filters
              actionButton(
                inputId = "IAV_reset_all",
                label = " Reset all",
                icon = icon(name = "refresh"),
                style = styles$button_style,
                width = styles$button_width
              ),
              offset = 1
            ),
            column(
              width = 4,
              # Button to random pick a merchant
              actionButton(
                inputId = "IAV_random_pick",
                label = " Random pick",
                icon = icon(name = "random"),
                style = styles$button_style,
                width = styles$button_width
              ),
              offset = 2
            )
          ),
          hr(),
          
          # Select merchant ID or ad
          fluidRow(
            selectizeInput(
              inputId = "IAV_selected_merchant_or_ad",
              label = "Select merchant or advertisement",
              choices = NULL,
              options = list(maxOptions = 1000, placeholder = 'Start typing or click here')
            ),
            style = "margin-left:10px; margin-right:10px"
          ),
          # Select advertisement ID (conditional UI)
          uiOutput("IAV_UI_select_ad"),
          hr(),
          
          # Select advertisement image (conditional UI)
          uiOutput("IAV_UI_select_ad_image"),
          br(),
          br(),
          # Render image if selected
          fluidRow(
            column(
              width = 12, 
              align = "center",
              imageOutput("IAV_ad_image")
            ),
            style = "margin-left:10px; margin-right:10px; margin-bottom:110px"
          )
          
        )
      )
    ),
    
    # Define the elements in the main panel
    mainPanel(
      # Define width of the panel
      width = 9,
      
      # Data table with advertisement info
      conditionalPanel(
        condition = "input.IAV_selected_merchant_or_ad.length > 0 ",
        
        column(
          width = 7,
          # Ad general info
          tableOutput(outputId = "IAV_ad_general_info"),
          br(),
          # Ad product info
          tableOutput(outputId = "IAV_ad_product_info"),
          br(),
          # Ad description
          tableOutput(outputId = "IAV_ad_description")
        ),
        
        column(
          width = 5,
          # Sale info
          tableOutput(outputId = "IAV_ad_price_info"),
          br(),
          # Shipping info
          tableOutput(outputId = "IAV_ad_shipping_info"),
          br(),
          # Bidding info
          tableOutput(outputId = "IAV_ad_bidding_info"),
          br(),
          # Scraping info
          tableOutput(outputId = "IAV_ad_scraping_info")
        )
        
      )
    )
    
  )
)
