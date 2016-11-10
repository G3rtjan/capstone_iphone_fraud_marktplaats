# capstone_iphone_fraud_marktplaats
This repo is used for the Capstone Project `iPhone fraud at Marktplaats` within the [GoDataDriven Accelerator Program](https://godatadriven.com/data-science-accelerator-program) and is executed by [Tim](https://github.com/timvink) & [Gertjan](https://github.com/G3rtjan) and evaluated by [Gio](https://github.com/gglanzani)

## Project Assignment

### iPhone fraud at Marktplaats

Lots of fraudsters at Marktplaats try to sell iPhones, but never actually send them. One of their
typical strategy is to ask to continue the conversation via Whatsapp/SMS, so that it will not be
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
