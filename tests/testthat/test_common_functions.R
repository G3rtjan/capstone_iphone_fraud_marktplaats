
testthat::context("Test common functions") 

testthat::test_that("determine_ads_to_scrape() works correctly", {
  
  testthat::expect_equal(
      determine_ads_to_scrape(ads_listed = data.frame(ad_id = c(1,2,3)), 
                              ads_seen = data.frame(ad_id = c(2,3,4), last_scrape = c(Sys.time(),Sys.time(),Sys.time())),
                              scrape_interval_h = 3), 
      c(1)
  )
  
  testthat::expect_equal(
    determine_ads_to_scrape(ads_listed = data.frame(ad_id = c("1","2","3")), 
                            ads_seen = data.frame(ad_id = "", last_scrape = Sys.time()),
                            scrape_interval_h = 3), 
    c(1,2,3)
  )
  
})
