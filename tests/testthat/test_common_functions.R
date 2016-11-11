
testthat::context("Test common functions") 

testthat::test_that("load_packages() and check_if_packages_loaded() work correctly", {
  packages <- c("dplyr","tidyr","lubridate")
  load_packages(packages_to_load = packages)
  loaded <- check_if_packages_loaded(packages_to_check = packages)
})

testthat::test_that("get_adv_id() works correctly", {
  testthat::expect_equal(
    get_adv_id('http://www.marktplaats.nl/a/telecommunicatie/mobiele-telefoons-apple-iphone/m1106778417-apple-telefoon-4s.html'), 
    "m1106778417"
  )
})
