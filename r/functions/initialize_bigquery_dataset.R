
# Function to initialize bigquery dataset to make sure it exists
initialize_bigquery_dataset <- function(project,bq_dataset,bq_table) {
  # Create bq_dataset if not yet existing
  if(!bq_dataset %in% bigrquery::list_datasets(project)) {
    success <- bigrquery::insert_dataset(project, bq_dataset, description = "Capstone project mpscraper")
    if(success) {
      print(paste0("BigQuery dataset '",bq_dataset,"' created succesfully"))
    } else {
      stop(paste0("BigQuery dataset '",bq_dataset,"' failed to be created..."))
    }
  } else {
    print(paste0("BigQuery dataset '",bq_dataset,"' already exists"))
  }
}
