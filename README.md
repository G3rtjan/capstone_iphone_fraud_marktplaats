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

#### How to build the mpscraper docker image
+ In the docker terminal, cd to your local copy of this repo (e.g. C:/GIT)
+ To build the docker image, run: 
	+ `docker build 'capstone_iphone_fraud_marktplaats' -t mpscraper`
+ To check whether the mpscraper docker image is now available, run: 
	+ `docker images`
+ To locally run the mpscraper docker image, run: 
	+ `docker run mpscraper`
+ To be able to push the mpscraper docker image to Google Cloud you need to tag it first, to link it to our Google project: 
	+ `docker tag mpscraper eu.gcr.io/capstoneprojectgt/mpscraper`
+ To push the mpscraper docker image to Google Cloud, run: 
	+ `docker -- push eu.gcr.io/capstoneprojectgt/mpscraper`
		+ NOTE: If not permitted to push, run 'gcloud docker' in Google Cloud SDK shell to authenticate yourself first
+ You should now be able to see the image in the [Containerregister](https://console.cloud.google.com/kubernetes/images/list?project=capstoneprojectgt)
		+ NOTE: You can manually deleter older images in the [Containerregister](https://console.cloud.google.com/kubernetes/images/list?project=capstoneprojectgt)

#### How to run the mpscraper docker image on Google Cloud
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


### Todo

- describe data collections proces
- describe different project folders
- describe shiny app
- do outlier detection
- update this README
