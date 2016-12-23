
# Function to get a list of advertisements from bigquery, with defined filtering method applied
get_ads_from_bigquery <- function(project,bq_dataset,bq_table,method = c("all", "open", "closed"),scrape_interval_h = numeric()) {

  # Determine filtering based on method
  method <- match.arg(method)
  closed_filter <- switch(method,
         all = "",
         open = "AND closed = 0",
         closed = "AND closed = 1")
  
  # Determine filtering based on scrape interval
  interval_filter <- ifelse(
    is.numeric(scrape_interval_h) & length(scrape_interval_h) > 0,
    paste0("AND ROUND((CURRENT_TIMESTAMP() - last_scrape)/1000000/3600,2) >= ",scrape_interval_h),
    ""
  )

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
    
    WHERE 1=1
      %s
      %s
    ORDER BY last_scrape asc
  ",project,bq_dataset,bq_table,closed_filter,interval_filter)
  
  # Query bq_table and return results
  bq_data <- bigrquery::query_exec(
    query = query,
    project = project, 
    max_pages = Inf
  )

  return(bq_data$ad_id)
}
