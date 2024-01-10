#!/usr/bin/bash

# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# requirements for tidyverse
sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev libharfbuzz-dev libfribidi-dev
# requirements for geospatial data science
sudo apt-get install -y libgdal-dev libproj-dev libgeos-dev libudunits2-dev libnode-dev libcairo2-dev libnetcdf-dev
# install R
sudo apt-get install -y r-base r-base-dev
