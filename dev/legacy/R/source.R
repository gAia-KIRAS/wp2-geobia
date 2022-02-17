# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SOURCE
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Source for libraries and pathes
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# CONTENT -----------------------------------------------------------------
# 1 PACKAGES
# 2 PATHES




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES --------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if(!require("pacman")) install.packages("pacman")
if(!require("devtools")) install.packages("devtools")  

pacman::p_load(here, renv, rgdal, raster, sf, mlr, rgrass7, RSAGA, link2GI, dplyr, data.table, e1071, ggplot2, lwgeom, rlist, directlabels)

if(!require("Lslide")) devtools::install_github(repo = "raff-k/Lslide")
if(!require("VLSM")) devtools::install_github(repo = "raff-k/VLSM")
pacman::p_load(Lslide, VLSM)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 PATHES ----------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

path_data <-file.path(here::here(), "data")
path_input <-file.path(path_data, "input")
path_validation <-file.path(path_input, "Validation")
path_output <-file.path(path_data, "output")
path_result <-file.path(path_data, "result")
path_R <-file.path(here::here(), "R")




# The following package(s) are used in the project:
# BBmisc         [1.11]
# BH             [1.69.0-1]
# DBI            [1.0.0]
# DT             [0.8]
# FNN            [1.1.3]
# KernSmooth     [2.23-15]
# LearnBayes     [2.15.1]
# Lslide         [raff-k/Lslide]
# MASS           [7.3-51.1]
# Matrix         [1.2-15]
# ParamHelpers   [1.12]
# R.methodsS3    [1.7.1]
# R.oo           [1.22.0]
# R.utils        [2.9.0]
# R6             [2.4.0]
# RColorBrewer   [1.1-2]
# RCurl          [1.95-4.12]
# RQGIS          [1.0.4]
# RSAGA          [1.3.0]
# Rcpp           [1.0.2]
# VLSM           [raff-k/VLSM]
# XML            [3.98-1.20]
# askpass        [1.1]
# assertthat     [0.2.1]
# backports      [1.1.4]
# bitops         [1.0-6]
# boot           [1.3-20]
# brew           [1.0-6]
# callr          [3.3.1]
# checkmate      [1.9.4]
# class          [7.3-15]
# classInt       [0.4-1]
# cleangeo       [0.2-2]
# cli            [1.1.0]
# clipr          [0.7.0]
# clisymbols     [1.2.0]
# coda           [0.19-3]
# codetools      [0.2-16]
# colorspace     [1.4-1]
# commonmark     [1.7]
# covr           [3.3.1]
# crayon         [1.3.4]
# crosstalk      [1.0.0]
# curl           [4.0]
# data.table     [1.12.2]
# deldir         [0.1-23]
# desc           [1.2.0]
# devtools       [2.2.0]
# digest         [0.6.20]
# directlabels   [2018.05.22]
# dplyr          [0.8.3]
# e1071          [1.7-2]
# ellipsis       [0.2.0.1]
# evaluate       [0.14]
# expm           [0.999-4]
# fansi          [0.4.0]
# fastmatch      [1.1-0]
# foreign        [0.8-71]
# fs             [1.3.1]
# future         [1.14.0]
# future.apply   [1.3.0]
# gdata          [2.18.0]
# ggplot2        [3.2.1]
# gh             [1.0.1]
# git2r          [0.26.1]
# globals        [0.12.4]
# glue           [1.3.1]
# gmodels        [2.18.1]
# gstat          [2.0-2]
# gtable         [0.3.0]
# gtools         [3.8.1]
# here           [0.1]
# hms            [0.5.1]
# htmltools      [0.3.6]
# htmlwidgets    [1.3]
# httpuv         [1.5.2]
# httr           [1.4.1]
# igraph         [1.2.4.1]
# ini            [0.3.1]
# intervals      [0.15.1]
# jsonlite       [1.6]
# labeling       [0.3]
# later          [0.8.0]
# lattice        [0.20-38]
# lazyeval       [0.2.2]
# link2GI        [0.3-7]
# listenv        [0.7.0]
# lwgeom         [0.1-7]
# magrittr       [1.5]
# maptools       [0.9-5]
# mclust         [5.4.5]
# memoise        [1.1.0]
# mgcv           [1.8-27]
# mime           [0.7]
# mlr            [2.15.0]
# munsell        [0.5.0]
# nlme           [3.1-137]
# openssl        [1.4.1]
# packrat        [0.5.0]
# parallelMap    [1.4]
# pillar         [1.4.2]
# pkgbuild       [1.0.5]
# pkgconfig      [2.0.2]
# pkgload        [1.0.2]
# plogr          [0.2.0]
# plyr           [1.8.4]
# praise         [1.0.0]
# prettyunits    [1.0.2]
# processx       [3.4.1]
# promises       [1.0.1]
# ps             [1.3.0]
# purrr          [0.3.2]
# quadprog       [1.5-7]
# raster         [3.0-2]
# rcmdcheck      [1.3.3]
# readr          [1.3.1]
# reshape2       [1.4.3]
# reticulate     [1.13]
# rex            [1.1.2]
# rgdal          [1.4-4]
# rgeos          [0.5-1]
# rgrass7        [0.2-1]
# rlang          [0.4.0]
# rlist          [0.4.6.1]
# roxygen2       [6.1.1]
# rprojroot      [1.3-2]
# rstudioapi     [0.10]
# rversions      [2.0.0]
# scales         [1.0.0]
# sessioninfo    [1.1.1]
# sf             [0.7-7]
# shapefiles     [0.7]
# shiny          [1.3.2]
# sourcetools    [0.1.7]
# sp             [1.3-1]
# spData         [0.3.0]
# spacetime      [1.2-2]
# spdep          [1.1-2]
# stringi        [1.4.3]
# stringr        [1.4.0]
# survival       [2.43-3]
# sys            [3.3]
# testthat       [2.2.1]
# tibble         [2.1.3]
# tidyselect     [0.2.5]
# units          [0.6-4]
# usethis        [1.5.1]
# utf8           [1.1.4]
# vctrs          [0.2.0]
# viridisLite    [0.3.0]
# whisker        [0.4]
# withr          [2.1.2]
# xml2           [1.2.2]
# xopen          [1.0.0]
# xtable         [1.8-4]
# xts            [0.11-2]
# yaml           [2.2.0]
# zeallot        [0.1.0]
# zoo            [1.8-6]
