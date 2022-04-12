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

## Conventions

### Coding style
**Python**
- Use [`black`](https://github.com/psf/black) as autoformatter
- Recommended editor: [VSCode](https://code.visualstudio.com/docs/python/python-tutorial)

**R**
- [tidyverse style guide](https://style.tidyverse.org/)
- Use `tidyverse`
- Use `sf` for vector data and `stars` for raster data.
- Recommended editor:
    - [RStudio](https://www.rstudio.com/)
    - [VScode](https://marketplace.visualstudio.com/items?itemName=Ikuyadeu.r) w/ [radian](https://github.com/randy3k/radian)


### Visualization
- Use of colors: For color coding data visualizations it is crucial to choose a palette that appropriately captures the underlying information. Please refer to color palettes as provided in the [HCL Wizard](https://hclwizard.org/) and use the respective `colorspace`  packages for [R](http://colorspace.r-forge.r-project.org/) and [Python](https://python-colorspace.readthedocs.io/en/latest/).
- Color advice for maps is available at the [Color Brewer](https://colorbrewer2.org/).
- Check out [Question-based visualizations](https://graphicsprinciples.github.io/qbv.html) for help on visualizing the underlying scientific questions of interest clearly and explicitly.


### Commit messages
- Commit messages should be clear and unambiguous.
- Please use imperative present tense for commit messages and avoid dots at the end.
- Please use consistent prefixes for commit messages (see [Numpy developement workflow](http://docs.scipy.org/doc/numpy/dev/gitwash/development_workflow.html#writing-the-commit-message)):

Please use the following prefixes for commit messages:

- `API:` an (incompatible) API change
- `BUG:` bug fix
- `DEP:` deprecate something, or remove a deprecated object
- `DEV:` development (tool or utility)
- `DOC:` documentation
- `MNT:` maintenance (e.g. renaming files)
- `REF:` code refactoring
- `REV:` revert an earlier commit
- `STY:` style changes / formatting
- `TST:` addition or modification of tests
