
# Function to reset scraping settings from bigquery
reset_settings_in_bigquery <- function(project,bq_dataset,bq_table,new_scrape_settings) {
  
  # Stop if dataset not exists
  if(!bq_dataset %in% bigrquery::list_datasets(project)) {
    stop(paste0("BigQuery dataset '",bq_dataset,"' does not exist!"))
  }
  
  # Remove old settings if they exist
  if(bigrquery::exists_table(project, bq_dataset, bq_table)) {
    bigrquery::delete_table(
      project = project, 
      dataset = bq_dataset, 
      table = bq_table
    )
  }
  
  # Upload new settings
  bigrquery::insert_upload_job(
    project = project, 
    dataset = bq_dataset, 
    table = bq_table, 
    values = data.frame(new_scrape_settings),
    create_disposition = "CREATE_IF_NEEDED",
    write_disposition = "WRITE_APPEND"
  )
  
}
