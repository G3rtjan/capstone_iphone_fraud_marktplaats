
#### setup ####
library(googleAuthR)
library(googleCloudStorageR)
library(tidyverse)
purrr::walk(list.files("r/functions", full.names = T), source)

#### settings ####
settings <- list(
  project = "capstoneprojectgt",
  # Cloud Storage settings
  scope = "https://www.googleapis.com/auth/devstorage.full_control",
  imageDir = "mpimages",
  # BigQuery settings
  bq_dataset = "mplaats_ads", 
  bq_table = "all_ads",
  bq_logs = "logs",
  bq_settings = "settings"
)

#### Connect ### 

options(googleAuthR.scopes.selected = c(settings$scope))
googleCloudStorageR::gcs_auth() # Authentication
# Get bucket and bucket info
bucket <- googleCloudStorageR::gcs_list_buckets(settings$project)
bucket_info <- googleCloudStorageR::gcs_get_bucket(bucket$name)
# Get bucket objects
objects <- get_add_images_from_gcloud(
  bucket_name = bucket$name,
  prefix = settings$imageDir
)
saveRDS(objects, "objects.RData")


gcs_download_url(objects[2], bucket = bucket$name)


class(objects)

get_set_of_images("mpimages")


