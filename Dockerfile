# image to use
FROM rocker/hadleyverse
MAINTAINER https://github.com/G3rtjan

# install additional R packages
RUN R -e "install.packages(c('devtools', 'bigrquery', 'selectr'), repos='https://cran.rstudio.com/')"

# add code in folder /code
ADD r /r
# set directory to location of code
WORKDIR /r

# Run the r script continuously
CMD ["Rscript", "main_marktplaats_scraper.R"]