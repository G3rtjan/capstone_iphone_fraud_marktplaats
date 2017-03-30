
# Define css code to be used in the ui
css <- "
.shiny-output-error { visibility: hidden; }
.shiny-output-error:before {
  visibility: visible;
  content: 'An error occurred! You can restart the app and try again, or if this error occurs frequently then please contact one of the developers...'; }
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
      title = "Individual Ads Viewer",
      source('view_individial_ads_ui.R', local = T)[1],
      icon = icon("search")
    )
    
  )
  
))
