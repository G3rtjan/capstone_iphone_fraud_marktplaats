
hash_image <- function(path) {
  hash <- phash(rgb_2gray(jpeg::readJPEG(path)), 
                hash_size = 8, 
                highfreq_factor = 4, 
                MODE = 'hash', 
                resize = "bilinear")
  
  tibble::tibble(
    image = basename(path),
    hash = hash
  )
}



