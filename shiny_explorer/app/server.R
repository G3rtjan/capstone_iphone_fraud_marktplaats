
# Dependency
library(shiny)
library(shinythemes)

# Function that defines the shiny server
shinyServer(function(input, output, session) {

  # Server functions for the first tab
  source('view_individial_ads_server.R',local = TRUE)

  # Stop server upon closing the browser tab
  session$onSessionEnded(stopApp)
  
})
