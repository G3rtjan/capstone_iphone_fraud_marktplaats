
# Function to upload logs of code execution to bigquery
upload_log_to_bigquery <- function(logs, project, bq_dataset, bq_table) {
  
  success <- bigrquery::insert_upload_job(
    project = project, 
    dataset = bq_dataset, 
    table = bq_table, 
    values = logs,
    create_disposition = "CREATE_IF_NEEDED",
    write_disposition = "WRITE_APPEND"
  )
  
  # Check success
  if(success) {
    print(paste0("Succesfully uploaded logs to '",bq_table,"' table in '",bq_dataset,"' dataset on BigQuery"))
  } else {
    stop(paste0("Failed to upload logs to '",bq_table,"' table in '",bq_dataset,"' dataset on BigQuery"))
  }
  
}
