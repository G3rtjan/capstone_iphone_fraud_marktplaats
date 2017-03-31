
hash_image <- function(path) {
  
  if(i %% 1000 == 0) print(sprintf("%s: hashed %s images", Sys.time(), i))
  i <<- i + 1
  
  hash <- tryCatch({
    OpenImageR::phash(OpenImageR::rgb_2gray(jpeg::readJPEG(path)), 
          hash_size = 8, 
          highfreq_factor = 4, 
          MODE = 'hash', 
          resize = "bilinear")
    }, 
    error = function(e) {
      NA_character_
    })
  
  tibble::tibble(
    image = basename(path),
    hash = hash
  )
}



