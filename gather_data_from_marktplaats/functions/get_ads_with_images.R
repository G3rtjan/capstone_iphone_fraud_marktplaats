
# Function to get all active ads which have images
get_ads_with_images <- function(project,bq_dataset,bq_table) {
  
  # Stop if dataset not exists
  if(!bq_dataset %in% bigrquery::list_datasets(project)) {
    stop(paste0("BigQuery dataset '",bq_dataset,"' does not exist!"))
  }
  
  # Return empty 
  if(!bigrquery::exists_table(project, bq_dataset, bq_table)) {
    print(paste0("BigQuery table '",bq_table,"' does not exist within BigQuery dataset '",bq_dataset,"', returning empty vector"))
    return(character())
  }
  
  # Define query
  query <- sprintf("
    SELECT
      ad_id
    FROM
    
      (SELECT 
        ad_id,
        min(number_of_photos) as n_images,
        max(closed) as closed
      FROM [%s:%s.%s]
      GROUP BY ad_id) ads

  WHERE closed = 0
    AND n_images >= 1
  ",project,bq_dataset,bq_table)
  
  # Query bq_table
  ads_with_images <- bigrquery::query_exec(
    query = query,
    project = project, 
    max_pages = Inf
  )
  
  # Return as sorted vector
  return(sort(ads_with_images$ad_id))
  
}
