
testthat::context("Test common functions") 

testthat::test_that("determine_ads_to_scrape() works correctly", {
  
  testthat::expect_equal(
      determine_ads_to_scrape(ads_listed = c(1,2,3), 
                                     ads_seen = c(2,3,4)), 
      c(1,2,3,4)
  )
  
  testthat::expect_equal(
    determine_ads_to_scrape(ads_listed = c("1","2","3"), 
                            ads_seen = character()), 
    c("1","2","3")
  )
  
})
