
# Define css code to be used in the ui
css <- "
.shiny-output-error { visibility: hidden; }
.shiny-output-error:before {
  visibility: visible;
  content: 'Please wait a few seconds...'; }
}
"
# Define button style
styles <- list(
  button_style = "padding:10px 0px; font-size:100%",
  button_width = "100%"
)

# Function that defines the shiny User Interface (UI)
shinyUI(fluidPage(theme = shinythemes::shinytheme("united"),
  
  # Apply css styling
  tags$style(type = "text/css", css),
  
  # Titel above the tabs
  navbarPage("MIFE: Marktplaats iPhone Fraud Explorer     ",
             
    # Name of the first tab
    tabPanel(
      title = "Training Ads Viewer",
      source('view_training_ads_ui.R', local = T)[1],
      icon = icon("bullseye")
    ),
    
    # Name of the first tab
    tabPanel(
      title = "Scrape New Ads Viewer",
      source('view_scrape_new_ads_ui.R', local = T)[1],
      icon = icon("search")
    )
    
  )
  
))
