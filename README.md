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

#### The web-scraper
We have build a custom R Package with a marktplaats scraper. The [marktplaats API](https://api.marktplaats.nl/docs/v1/overview.html) is not usable because "Through the API you only have access to your own ads. Ads from other advertisers are not accessible.". The marktplaats scraper package is located in a separate github repo: [mpscraper](https://github.com/timvink/mpscraper).

#### The docker container
We built a docker container to describe the R environment which can run our mpscraper package.
If you want to build this docker image locally, you can follow these steps:

+ In the docker terminal, cd to your local copy of this repo (e.g. C:/GIT)
+ To build the docker image, run: `docker build 'capstone_iphone_fraud_marktplaats' -t mpscraper`
+ To check whether the mpscraper docker image is now available, run: `docker images`
+ To locally run the mpscraper docker image, run: `docker run mpscraper`
+ To be able to push the mpscraper docker image to Google Cloud you need to tag it first, to link it to our Google project: `docker tag mpscraper eu.gcr.io/capstoneprojectgt/mpscraper`
+ To push the mpscraper docker image to Google Cloud, run: `docker -- push eu.gcr.io/capstoneprojectgt/mpscraper`
		+ _note_: If not permitted to push, run 'gcloud docker' in Google Cloud SDK shell to authenticate yourself first
+ You should now be able to see the image in the [Containerregister](https://console.cloud.google.com/kubernetes/images/list?project=capstoneprojectgt)
    + NOTE: You can manually deleter older images in the [Containerregister](https://console.cloud.google.com/kubernetes/images/list?project=capstoneprojectgt)

#### Scheduling the scraper

We choose the google cloud to run our docker image with our mpscraper package.
When scraping a lot of ads you need to deal with issues such as server errors, weird ads, duplicates etc.
All that logic can be found in the `/gather_data_from_marktplaats` folder. We scheduled regular runs of our container
using the google compute instance manager. We use google bigquery to store the results. We also used this database in our code to know which ads we need to revisit; this way we can determine when ads are closed or merchants are removed.

If you want to run the mpscraper docker image on the google cloud, you can follow these steps:

+ Login to your [Google Cloud Platform](console.cloud.google.com) dashboard
+ [Activate the Google Cloud Shell](https://cloud.google.com/shell/docs/starting-cloud-shell)
+ Run the following code to start a single container:
	+ `gcloud config set compute/zone europe-west1-c`
	+ `gcloud container clusters create mpscraper --num-nodes 1`
	+ `gcloud auth application-default login`
		+ Follow instruction to copy the link to your browser and return the specified code
		+ The reason to do this is described [here](https://developers.google.com/identity/protocols/application-default-credentials)
	+ `kubectl run mpscraper --image=eu.gcr.io/capstoneprojectgt/mpscraper --port=8080`
	+ `kubectl expose deployment mpscraper  --type="LoadBalancer"`
+ To check the status of the container, run:
	+ `kubectl get service mpscraper`
+ After some time, you can check if the container has written data to [Google BigQuery](https://bigquery.cloud.google.com/dataset/capstoneprojectgt:mplaats_ads)
+ To remove the container, run:
	+ `gcloud container clusters delete mpscraper`

### Data preparation

We ran the scraper for ±2 months and collected 2.680.047 snapshots of 91.562 unique ads, and 275.027 pictures of iPhones.
In the folder `/fraud_detection` we download and aggregate this data into features that can detect fraud. Some features suspected to indicate fraud:

- number of name changes of merchant
- merchant account is younger than average merchant account
- uniqueness of ad photos that are used
- underpriced iphone
- merchant has contact information (phone number)
- ad description asks to contact by sms/whatsapp/email
- average number of ads the merchants has open

The images we hashed using a phash algoritm. By using a map between ad_id and the image hashes use, we were able to identify features such as scoring how unique the most unique foto of an ad is.

### Modeling

In `/fraud_detection/3-modelling.R` we have tried two different approaches to recognize fraud:

- A simple algoritm that manually weights the different fraud indicators and scores each ad. This is an un-supervised approach.
- We transformed the problem to a supervised binary classification problem by using the fact if merchants are removed as a label and training a XGBOOST model.

The latter approach worked best when do a manual evaluation by viewing different ads.  

### Viewing ads

Because many ads are not online on Marktplaats anymore, we built a custom shiny app in R.
The web app displays the data we have collected on a certain ad or merchant, as well as
the corresponding ads.

![fraudulent ad](data/img/feature_imp.png)

### Results

We were able to use the tools we built to identify fraudulent ads. One example is a merchant that has multiple ads with the same text and images, but kept changing his name (id stays constant).

![fraudulent ad](data/img/fraud_ad1.png)
![fraudulent ad](data/img/fraud_ad2.png)
