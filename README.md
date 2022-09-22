# gAIa - WP2

> Automatisierte Detektion von Hangrutschungen in digitalen Höhenmodellen


## WP 2 Description

### Objectives

> - Automatisierte Detektion von Massenbewegungen aus ALS-DHMs mittels GEOBIA - (GEOgraphic-Object-Based Image Analysis)
> - Erstellung eines homogenen, objektiv abgeleiteten Rutschungsinventars
> - Modellvalidierung: Vergleich der Ergebnisse mit vorliegenden, manuell kartierten Rutschungspolygonen


### Tasks

- Task 2.1: DHM-Preprocessing:
- Task 2.2: Detektion von Hangrutschungen und Segmentierung:
- Task 2.2: Detektion von Hangrutschungen und Segmentierung:


### Approach

After the initial idea to employ GEOBIA as described by Knevels et al. (2019)[^1], focus is now on re-implementing an approach based on Pawluszek (2019)[^2].

<div align="center">

<img src="https://www.mdpi.com/ijgi/ijgi-08-00321/article_deploy/html/images/ijgi-08-00321-g003.png" align="center" height="300" alt="overall approach">

<img src="https://www.mdpi.com/ijgi/ijgi-08-00321/article_deploy/html/images/ijgi-08-00321-g004.png" align="center" height="300" alt="OBIA approach">

</div>

[^1]: Knevels, R.; Petschko, H.; Leopold, P.; Brenning, A. Geographic Object-Based Image Analysis for Automated Landslide Detection Using Open Source GIS Software. *ISPRS Int. J. Geo-Inf.* **8**, 551. (2019). https://doi.org/10.3390/ijgi8120551 .

[^2]: Pawłuszek, K.; Marczak, S.; Borkowski, A.; Tarolli, P. Multi-Aspect Analysis of Object-Oriented Landslide Detection Based on an Extended Set of LiDAR-Derived Terrain Features. *ISPRS Int. J. Geo-Inf.* **8**, 321 (2019). https://doi.org/10.3390/ijgi8080321.


## Remote repositories

```sh
$ git remote -v
```
```sh
egitlab https://egitlab.zamg.ac.at/zamg-eo/gaia.git (fetch)
egitlab https://egitlab.zamg.ac.at/zamg-eo/gaia.git (push)
github  git@github.com:gAia-KIRAS/wp2-geobia.git (fetch)
github  git@github.com:gAia-KIRAS/wp2-geobia.git (push)
origin  git@vgitlab.zamg.ac.at:zamg-eo/forschungsprojekte/gaia.git (fetch)
origin  git@vgitlab.zamg.ac.at:zamg-eo/forschungsprojekte/gaia.git (push)
```

## Overview 

The general structure is as follows:
- `cfg`: configuration files
- `dat`: data sets
- `dev`: development (scripts)
- `doc`: documentation (e.g. reports, dissemination)
- `gis`: (Q)GIS-projects
- `org`: organizational stuff (e.g. contract, accounting)
- `plt`: plots / figures

Specifically, the data folder `dat` is structured as follows:

```sh
dat
├── interim    » Intermediate data that has been transformed.
├── processed  » Canonical output data sets.
├── raw        » The original, immutable data dump.
└── reporting  » Final data sets for delivery/reporting.
```

