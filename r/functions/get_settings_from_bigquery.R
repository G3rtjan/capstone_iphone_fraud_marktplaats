
# Function to get a list of advertisements from bigquery, with defined filtering method applied
get_settings_from_bigquery <- function(project,bq_dataset,bq_table) {
  
  # Stop if dataset not exists
  if(!bq_dataset %in% bigrquery::list_datasets(project)) {
    stop(paste0("BigQuery dataset '",bq_dataset,"' does not exist!"))
  }
  
  # Return default settings if table not exists in dataset
  if(!bigrquery::exists_table(project, bq_dataset, bq_table)) {
    print(paste0("BigQuery table '",bq_table,"' does not exist within BigQuery dataset '",bq_dataset,"', returning default settings"))
    list(
      # mpscraper settings
      search_url = "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex",
      ads_per_minute = 120, # limit download rate to prevent being blocked by hammering marktplaats server
      report_every_nth_scrape = 100, # how chatty do you want to be
      number_of_tries = 3, # in case of connection time-outs
      scrape_interval = 3, # interval between two scrapes, in hours
      # BigQuery settings
      batch_size = 1000
    ) %>% 
      return()
  }
  
  # Define query
  query <- sprintf("
    SELECT
      *
    FROM [%s:%s.%s]
  ",project,bq_dataset,bq_table)
  
  # Query bq_table and return results
  bigrquery::query_exec(
    query = query,
    project = project, 
    max_pages = Inf
  ) %>% 
    return()

}
