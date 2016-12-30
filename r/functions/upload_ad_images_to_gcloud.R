
# Function to upload images linked to a specific ad to Google Cloud
upload_ad_images_to_gcloud <- function(ad_id, file_path, bucket_name) {
  
  # Save all images to local disk
  scrape_adv_images(
    ad_id = ad_id,
    storage_dir = file_path
  )
  
  # List all stored images
  images <- list.files(path = file_path)
  # Filter relevant images
  images <- images[grepl(ad_id,images)]
  
  # Upload each images
  for(image in images){
    googleCloudStorageR::gcs_upload(
      file = file.path(file_path,image),
      bucket = bucket_name,
      name = file.path(file_path,image)
    )
  }
  
  invisible()
}
