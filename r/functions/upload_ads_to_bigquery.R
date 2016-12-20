
# Function to upload details of scraped advertisements to bigquery
upload_ads_to_bigquery <- function(scraped_ads,project,bq_dataset,bq_table) {

  success <- bigrquery::insert_upload_job(
    project = project, 
    dataset = bq_dataset, 
    table = bq_table, 
    values = scraped_ads,
    create_disposition = "CREATE_IF_NEEDED",
    write_disposition = "WRITE_APPEND"
  )
  
  # Check success
  if(success) {
    print(paste0("Succesfully uploaded scraped ads to '",bq_table,"' table in '",bq_dataset,"' dataset on BigQuery"))
  } else {
    stop(paste0("Failed to upload scraped ads to '",bq_table,"' table in '",bq_dataset,"' dataset on BigQuery"))
  }
  
}
