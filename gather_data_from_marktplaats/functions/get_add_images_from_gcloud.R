
# Function to get list of all images from Google Cloud
get_add_images_from_gcloud <- function(bucket_name,prefix) {
  
  # Get first set
  extract <- get_set_of_images(bucket_name,prefix)
  # Initialize dataset
  images <- extract$images
  
  while(!is.null(extract$next_token)) {
    # Get next extract
    extract <- get_set_of_images(bucket_name,prefix,extract$next_token)
    # Add to images
    images <- c(images,extract$images)
  }
  
  return(images)
  
}

# Function to get a limited list of images (max 1000 per call!)
get_set_of_images <- function(bucket_name,prefix="",pageToken="") {
  
  # Define api call
  api_call <- googleAuthR::gar_api_generator(
    baseURI = "https://www.googleapis.com/storage/v1/", 
    path_args = list(
      b = bucket_name, 
      o = ""
    ),
    pars_args = list(
      prefix = prefix,
      pageToken = pageToken
    )
  )
  
  # Get response from call
  response <- api_call()
  
  # Extract and return results
  data <- response$content$items %>% 
    dplyr::select(name)
  next_token <- response$content$nextPageToken
  
  return(
    list(
      images = data$name, 
      next_token = next_token
    )
  )
  
}
