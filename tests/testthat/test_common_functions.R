
testthat::context("Test common functions") 

testthat::test_that("determine_ads_to_scrape() works correctly", {
  
  testthat::expect_equal(
      determine_ads_to_scrape(ads_listed = c(1,2,3), 
                                     ads_seen = c(2,3,4)), 
      c(1,2,3,4)
  )
  
})


testthat::test_that("get_adv_id() works correctly", {
  testthat::expect_equal(
    get_adv_id('http://www.marktplaats.nl/a/telecommunicatie/mobiele-telefoons-apple-iphone/m1106778417-apple-telefoon-4s.html'), 
    "m1106778417"
  )
})
