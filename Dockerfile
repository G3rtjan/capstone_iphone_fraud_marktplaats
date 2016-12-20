# image to use
FROM rocker/hadleyverse
MAINTAINER https://github.com/G3rtjan
# install additional R packages
RUN R -e "install.packages(c('devtools', 'bigrquery', 'selectr'), repos='https://cran.rstudio.com/')"
RUN R -e "devtools::install_github('timvink/mpscraper')"

#Install Cron
RUN apt-get update
RUN apt-get -y install cron
# Add crontab file in the cron directory
ADD crontab /cron/crontab
# Give execution rights on the cron job
RUN chmod 0644 /cron/crontab
# Create the log file to be able to run tail
RUN touch /log/cron.log

# add code in folder /code
ADD code /code
# set directory to location of code
#WORKDIR /code
# start R script in code folder
#CMD ["Rscript", "test.R"]

# Run the command on container startup
CMD cron && tail -f /log/cron.log