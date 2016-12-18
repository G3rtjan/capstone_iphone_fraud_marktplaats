# rocker image to use
FROM rocker/hadleyverse

# install additional packages
RUN R -e "install.packages(c('devtools', 'bigrquery', 'selectr'), repos='https://cran.rstudio.com/')"

# add code in folder /code
ADD code /code

# set directory to location of code
WORKDIR /code

# start R script in code folder
CMD ["Rscript", "test.R"]