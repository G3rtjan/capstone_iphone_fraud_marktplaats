
# Function to get a list of advertisements from bigquery, with defined filtering method applied
get_ads_from_bigquery <- function(project,bq_dataset,bq_table,method = c("all", "open", "closed")) {

  # Determine filtering based on method
  method <- match.arg(method)
  closed_filter <- switch(method,
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
      ad_id,
      closed,
      last_scrape
    FROM
    
      (SELECT 
        ad_id,
        max(closed) as closed,
        max(time_retrieved) as last_scrape
      FROM [%s:%s.%s]
      GROUP BY ad_id) ads
    
    %s
    ORDER BY last_scrape asc
  ",project,bq_dataset,bq_table,closed_filter)
  
  # Query bq_table and return results
  bq_data <- bigrquery::query_exec(
    query = query,
    project = project, 
    max_pages = Inf
  )

  return(bq_data)
}
