# capstone_iphone_fraud_marktplaats
This repo is used for the Capstone Project `iPhone fraud at Marktplaats` within the [GoDataDriven Accelerator Program](https://godatadriven.com/data-science-accelerator-program) and is executed by [Tim](https://github.com/timvink) & [Gertjan](https://github.com/G3rtjan) and evaluated by [Gio](https://github.com/gglanzani)

## Project Assignment

### iPhone fraud at Marktplaats

Lots of fraudsters at Marktplaats try to sell iPhones, but never actually send them. One of their
typical strategies is to ask to continue the conversation via Whatsapp/SMS, so that it will not be
monitored by Marktplaats. In this project you need to do the following:

+ Immediately start scraping iPhones listing so that when you start the next step you have 2/3
  weeks of data;
+ Manually search for the ones containing the words Whatsapp/SMS;
+ Manually categorize the ads that you think are fraudulent (you can see it from the price, from
  the location, and the reason it gives for not wanting to be contact via Marktplaats messages);
+ Train a model to find the fraudulent listings in a streaming fashion.

#### T-shirt

If you saved the images as well when scraping, try to see if fraudsters are reusing the images
once their listings are taken offline. If so, add image hashing to your model.

## Project Execution

### Data Collection

We have build a custom R Package with a marktplaats scraper. The [marktplaats API](https://api.marktplaats.nl/docs/v1/overview.html) is not usable because "Through the API you only have access to your own ads. Ads from other advertisers are not accessible."

#### Functions

- Get overview of available advertisements
	- `get_number_of_adv_pages()`: determines the number of pages with advertisements
	- `get_adv_urls_from_page()`: gets the url for each of the advertisements on a search results page
	- `get_adv_titles_from_page()`: gets the title for each of the advertisements on a search results page
	- `combine_adv_info_from_page()`: combines the titles and urls of advertisements from a search results page
	- `get_advs_overview_from_page()`: gets the info on all advertisments on a search results page
- Get detailed information on each advertisement
	- `get_css_element()`: gets a specific css element from a html page
	- `get_n_of_advs_of_counterparty()`: gets the number of advertisements that a counterparty is currently hosting
	- `check_adv_available()`: checks whether a specific advertisement is still available
- Get images linked to each advertisement
	- `get_urls_to_adv_images()`: gets the url for each of the images used in an advertisement
	- `download_adv_images_as_jpg()`: downloads images used in an advertisement and stores them in a jpg format in the specified directory
	- `get_adv_images()`: downloads and stores all images used in the advertisement indicated in the specified url

#### Scripts
- `gather_iphone_advs_data()`: Scraping all available advertisements on Marktplaats within the group *Telecommunicatie* and column *Mobiele telefoons | Apple iPhone* while using the query *iphone* and sorting by *date desc*, to collect the following informatie for each advertisement:
	- price
	- number of views
	- number of favorites
	- displayed since
	- shipping information
	- counterparty name
	- counterparty number of advertisements
	- counterparty active since
	- counterparty location
	- list of biddings
	- list of product attributes
	- advertisement description
	- advertisement images
