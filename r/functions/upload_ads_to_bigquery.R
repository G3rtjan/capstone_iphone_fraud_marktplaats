
# Function to upload details of scraped advertisements to bigquery
upload_ads_to_bigquery <- function(scraped_ads,project,bq_dataset,bq_table,batch_size = 1000) {

  upload_batch <- function(batch_of_ads) {
    bigrquery::insert_upload_job(
      project = project, 
      dataset = bq_dataset, 
      table = bq_table, 
      values = batch_of_ads,
      create_disposition = "CREATE_IF_NEEDED",
      write_disposition = "WRITE_APPEND"
    ) %>% 
      return()
  }
  
  successes<- ads %>% 
    dplyr::mutate(
      nr = 1,
      batch = floor(cumsum(nr)/batch_size) + 1
    ) %>% 
    split(.$batch) %>% 
    purrr::map_df(upload_batch)
  
  # Check success
  if(all(successes)) {
    print(paste0("Succesfully uploaded scraped ads to '",bq_table,"' table in '",bq_dataset,"' dataset on BigQuery"))
  } else {
    stop(paste0("Failed to upload scraped ads to '",bq_table,"' table in '",bq_dataset,"' dataset on BigQuery"))
  }
  
}
