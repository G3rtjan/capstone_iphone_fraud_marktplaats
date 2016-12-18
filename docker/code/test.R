
print('SENDING START MESSAGE')

project <- "polynomial-coda-151914"

dataset <- "mplaats_advs"

if(!dataset %in% bigrquery::list_datasets(project)) {
  bigrquery::insert_dataset(project, dataset, description = "Data on total set of advertisements", friendlyName = NULL)
  print('FINISHED CREATING DATASET')
} else {
  print('DATASET ALREADY EXISTS')
}

bigrquery::insert_upload_job(project, dataset, "started", data.frame(started = 'YES!', time = Sys.time()), billing = project,
                  create_disposition = "CREATE_IF_NEEDED",
                  write_disposition = "WRITE_APPEND")
  


print('INSTALLING timvink/mpscraper')
devtools::install_github("timvink/mpscraper",force = TRUE)

print('LOADING timvink/mpscraper')
library(mpscraper)
library(XML)



print('SCRAPING MP')

url <- "http://www.marktplaats.nl/z/telecommunicatie/mobiele-telefoons-apple-iphone/iphone.html?query=iphone&categoryId=1953&sortBy=SortIndex"

ads <- try(
  mpscraper::list_advertisements(
    url = url,
    advertisement_type = "both",
    max_pages = 3
  )
)

head(ads)



print('FINISHED SCRAPING')
  
if(class(ads) == "data.frame") {
  table <- 'ads'

  bigrquery::insert_upload_job(project, dataset, table, ads, billing = project,
                    create_disposition = "CREATE_IF_NEEDED",
                    write_disposition = "WRITE_APPEND")

  print('FINISHED UPLOADING TO TABLE')
} else {
  print('NOT UPLOADING TO TABLE')
}

if(class(ads) == "try-error") {
  table <- 'errors'

  error <- data.frame(error = as.character(ads), time = Sys.time())

  bigrquery::insert_upload_job(project, dataset, table, error, billing = project,
                    create_disposition = "CREATE_IF_NEEDED",
                    write_disposition = "WRITE_APPEND")

  print('FINISHED UPLOADING ERROR')
} else {
  print('NOT UPLOADING ERROR')
}

#bigrquery::delete_dataset(project, dataset, deleteContents = TRUE)
