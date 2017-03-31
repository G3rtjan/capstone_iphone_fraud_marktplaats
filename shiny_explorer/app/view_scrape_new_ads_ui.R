
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
                inputId = "SNA_reset_all",
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
                inputId = "SNA_random_pick",
                label = " Random pick",
                icon = icon(name = "random"),
                style = styles$button_style,
                width = styles$button_width
              ),
              offset = 2
            )
          ),
          hr(),
          
          # Type or paste your own ad_id
          fluidRow(
            textInput(
              inputId = "SNA_typed_ad_id",
              label = "Type or paste your own iPhone ad id",
              placeholder = 'Type or paste'
            ),
            style = "margin-left:10px; margin-right:10px"
          ),
          
          # Select merchant ID or ad
          fluidRow(
            selectizeInput(
              inputId = "SNA_selected_ad",
              label = "OR select a currently listed ad id to scrape",
              choices = global_vars$new_ads,
              options = list(maxOptions = 1000, placeholder = 'Start typing or click here')
            ),
            style = "margin-left:10px; margin-right:10px"
          ),
          
          # Select advertisement image (conditional UI)
          uiOutput("SNA_UI_select_ad_image"),
          br(),
          br(),
          # Render image if selected
          fluidRow(
            column(
              width = 12, 
              align = "center",
              imageOutput("SNA_ad_image")
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
        condition = "input.SNA_selected_ad.length > 0 ",
        
        column(
          width = 7,
          # Fraud score info
          br(),
          tableOutput(outputId = "SNA_fraud_score"),
          br(),
          br(),
          # Ad general info
          tableOutput(outputId = "SNA_ad_general_info"),
          br(),
          # Ad description
          tableOutput(outputId = "SNA_ad_description")
        ),
        
        column(
          width = 5,
          # Sale info
          tableOutput(outputId = "SNA_ad_price_info"),
          br(),
          # Ad product info
          tableOutput(outputId = "SNA_ad_product_info"),
          br(),
          # Bidding info
          tableOutput(outputId = "SNA_ad_bidding_info")
        )
        
      )
    )
    
  )
)
