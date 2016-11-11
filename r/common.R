
#' Load R packages
#' 
#' \code{load_packages} (tries to) load a specified set of R packages.
#' 
#' The function tries to load the set of packages specified in the function 
#' call. If a package is not available, then the function tries to install the 
#' package after which another attempt is made to load it. The functions stops 
#' with a message if one of the packages could not be loaded or installed.
#' 
#' @param packages_to_load Vector of package names (each of which is a character
#'   string).
#' @param lib_path File path to the location of the library to use. Default is 
#'   the first element returned by \code{.libPaths()}.
#'   
#' @return No return if successful, stops with error if one of the packages 
#'   could not be loaded or installed.
#'   
#' @export
#' @examples
#' 
#' load_packages(packages_to_load = c('dpalyr','tidyr','lubridate))
#' 
load_packages <- function(packages_to_load, lib_path = .libPaths()[1]) {
  for(package in packages_to_load) {
    # Check if loading succeeds
    load_succeeded <- suppressMessages(
      suppressWarnings(
        library(
          package = package, 
          lib.loc = lib_path, 
          character.only = TRUE, 
          logical.return = TRUE
        )
      )
    )
    # Try to install if loading did not succeed
    if(!load_succeeded) {
      install.packages(
        pkgs = package,
        lib = lib_path,
        repos = "http://cran.us.r-project.org"
      )
      # Check if loading succeeds after installing
      load_succeeded <- suppressMessages(
        suppressWarnings(
          library(
            package = package, 
            lib.loc = lib_path, 
            character.only = TRUE, 
            logical.return = TRUE
          )
        )
      )
      # Stop if package could not be installed
      if(!load_succeeded) {
        stop(paste0("\nPackage ",package," could not be found or installed..."))
      }
    }
  }
}

#' Check if R packages are loaded
#' 
#' \code{check_if_packages_loaded} checks whether a specified set of R packages 
#' has been loaded.
#' 
#' The function checks whether a specified set package has been loaded in the 
#' current R environment.
#' 
#' @param packages_to_check Vector of package names (each of which is a 
#'   character string).
#'   
#' @return No return if all packages have been loaded, stops with error if one 
#'   of the packages has not been loaded.
#'   
#' @export
#' @examples
#' 
#' check_if_packages_loaded(packages_to_check = c('dplyr','tidyr','lubridate))
#' 
check_if_packages_loaded <- function(packages_to_check) {
  # Determine currently loaded packages
  loaded_packages <- search()
  # Keep track of not loaded packages
  not_loaded <- c()
  # Check each package
  for(package in packages_to_check) {
    loaded <- paste0("package:",package) %in% loaded_packages
    if(!loaded) {
      not_loaded <- append(not_loaded,package)
    }
  }
  # Check whether one ore more packages have not been loaded
  if(length(not_loaded) > 0) {
    # Message stating which packages are (not) loaded
    stop(paste0("\nThe following packages have not been loaded:\n",paste0(not_loaded,collapse=", ")))
  }
}

#' Get adv_id from an adv url
#' 
#' \code{get_adv_id} extracts the advertisement id from its url.
#' 
#' The function uses a regular expression to extract the advertisement id from 
#' the advertisement url. The advertisement id starts with either an 'a' (for 
#' business advertisements) or a 'm' (for private advertisements) and ends with 
#' 10 digits.
#' 
#' @param adv_url String containing the advertisement url, which contains the 
#'   advertisement id.
#'   
#' @return a string object.
#'   
#' @export
#' @examples
#' 
#' get_adv_id(adv_url = 'http://www.marktplaats.nl/a/telecommunicatie/mobiele-telefoons-apple-iphone/m1106778417-apple-telefoon-4s.html')
#' 
get_adv_id <- function(adv_url) {
  stringr::str_extract(adv_url,'[am][0-9]{1,10}') %>% 
    return()
}
