
# Function to get a list of advertisements from bigquery, with defined filtering method applied
get_ads_from_bigquery <- function(project,bq_dataset,bq_table,method = c("all", "open", "closed")) {

  # Determine filtering based on method
  method <- match.arg(method)
  where_filter <- switch(method,
         all = "",
         open = "WHERE closed = 0",
         closed = "WHERE closed = 1")
  
  # Stop if dataset not exists
  if(!bq_dataset %in% bigrquery::list_datasets(project)) {
    stop(paste0("BigQuery dataset '",bq_dataset,"' does not exist!"))
  }
  
  # Return empty vector if table not exists in dataset
  if(!bigrquery::exists_table(project, bq_dataset, bq_table)) {
    print(paste0("BigQuery table '",bq_table,"' does not exist within BigQuery dataset '",bq_dataset,"'. Returning empty vector."))
    return(character())
  }
  
  # Define query
  query <- sprintf("
    SELECT
      adv_id
    FROM
    
      (SELECT 
        adv_id,
        max(closed) as closed
      FROM [%s:%s.%s]
      GROUP BY adv_id)ads
    
    %s
  ",project,bq_dataset,bq_table,where_filter)
  
  # REMOVE THIS TEMP QUERY
  query <- sprintf("
    SELECT
      adv_id
    FROM
    
      (SELECT 
        adv_id,
        max(0) as closed
      FROM [%s:%s.%s]
      GROUP BY adv_id) ads
    
    %s
    ",project,bq_dataset,bq_table,where_filter)
  print('TO DO: DONT FORGET TO REMOVE TEMP QUERY!')
  
  # Query bq_table and return results
  bq_data <- bigrquery::query_exec(
    query = query,
    project = project, 
    max_pages = Inf
  )

  return(bq_data$ad_id)
}
