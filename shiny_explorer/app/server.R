
# Dependency
library(shiny)
library(shinythemes)

# Function that defines the shiny server
shinyServer(function(input, output, session) {

  # Server functions for the first tab
  source('view_training_ads_server.R',local = TRUE)
  
  # Server functions for the second tab
  source('view_scrape_new_ads_server.R',local = TRUE)

  # Stop server upon closing the browser tab
  session$onSessionEnded(stopApp)
  
})
