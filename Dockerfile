FROM rocker/tidyverse
MAINTAINER Michal Ludwicki (Ludwickim@gmail.com)

RUN apt-get -qqy update && apt-get install -qqy \
        openssh-client \
        qpdf
        
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleAuthR \ 
    googleComputeEngineR \ 
    googleAnalyticsR \ 
    searchConsoleR \ 
    googleCloudStorageR \
    bigQueryR \ 
    zip \
	stringr\
## install Github packages
    && installGithub.r MarkEdmondson1234/youtubeAnalyticsR \
                       MarkEdmondson1234/googleID \
                       cloudyr/googleCloudStorageR \
                       cloudyr/googleComputeEngineR \
## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds