# gAIa

> Predicting landslides - Entwicklung von Gefahrenhinweiskarten für Hangrutschungen aus konsolidierten Inventardaten

- **Funding**: KIRAS | FFG
- **Focus**: *3.1.3 Innovatives Geodatenmanagement zur Erfassung und Analyse von Massenbewegungen vor/während/nach dem Ereigniseintritt*
- **Lead**: SBA Research gGmbH
- **Partner**:
    - GeoSphere Austria (GSA)
    - ~~Zentralanstalt für Meteorologie und Geodynamik (ZAMG)~~
    - ~~Geologische Bundesanstalt (GBA)~~
    - Austrian Institute of Technology (AIT)
    - GeoVille Information Systems and Data Processing GmbH (GeoVille)
    - Disaster Competence Network Austria (DCNA)
    - Bundesministerium für Landesverteidigung (BMLV)
- **Duration**: 01.10.2021 - ~~30.09.2023~~ 31.03.2024

## Remote repositories

This is a general repository of tasks implemented by GeoSphere Austria within the gAia project.
Currently, the internal GitLab repository has a push mirror to https://github.com/gAia-KIRAS/wp2-geobia.

```sh
$ git remote -v
```
```sh
# official gAia repo for wp2
github-wp2  git@github.com:gAia-KIRAS/wp2-geobia.git (fetch)
github-wp2  git@github.com:gAia-KIRAS/wp2-geobia.git (push)
# internal (GeoSphere Austria)
origin  git@gitlab.geosphere.at:klifofo-kleo/forschungsprojekte/gaia.git (fetch)
origin  git@gitlab.geosphere.at:klifofo-kleo/forschungsprojekte/gaia.git (push)
```

## Repo structure 

The general structure is as follows:
- `cfg`: configuration files
- `dat`: data sets
- `dev`: development (scripts)
- `doc`: documentation (e.g. reports, dissemination)
- `gis`: (Q)GIS-projects
- `org`: organizational stuff (e.g. contract, accounting)
- `plt`: plots / figures

Specifically, the data folder `dat` is structured as follows:

```console
dat
├── interim    » Intermediate data that has been transformed.
├── processed  » Canonical output data sets.
├── raw        » The original, immutable data dump.
└── reporting  » Final data sets for delivery/reporting.
```



## WP2

> Automatisierte Detektion von Hangrutschungen in digitalen Höhenmodellen

### Objectives

> - Automatisierte Detektion von Massenbewegungen aus ALS-DHMs mittels GEOBIA - (GEOgraphic-Object-Based Image Analysis)
> - Erstellung eines homogenen, objektiv abgeleiteten Rutschungsinventars
> - Modellvalidierung: Vergleich der Ergebnisse mit vorliegenden, manuell kartierten Rutschungspolygonen

### Tasks

- Task 2.1: DHM-Preprocessing
- Task 2.2: Detektion von Hangrutschungen und Segmentierung
- Task 2.2: Detektion von Hangrutschungen und Segmentierung

### Approach

GEOBIA approaches by Knevels et al. (2019)[^1] and Pawluszek (2019)[^2] were not considered feasible. Simple mean-shift segmentation was tried instead.

### Repo
https://github.com/gAia-KIRAS/wp2-geobia


## WP5

> Vorhersage und Visualisierung von Hangrutschungen

### Tasks

- Task 5.1: Modell-Preprocessing: Erstellung von Klimaindizes, Ableitung geomorphologischer Grundeinheiten und Entwicklung der Netzwerk-Architektur
- Task 5.2 Training der Vorhersage-Modelle und Validierung
- Task 5.3 Visualisierung und Interpretation

### Repo
https://github.com/gAia-KIRAS/wp5_susceptibility

## References

[^1]: Knevels, R.; Petschko, H.; Leopold, P.; Brenning, A. Geographic Object-Based Image Analysis for Automated Landslide Detection Using Open Source GIS Software. *ISPRS Int. J. Geo-Inf.* **8**, 551. (2019). https://doi.org/10.3390/ijgi8120551.

[^2]: Pawłuszek, K.; Marczak, S.; Borkowski, A.; Tarolli, P. Multi-Aspect Analysis of Object-Oriented Landslide Detection Based on an Extended Set of LiDAR-Derived Terrain Features. *ISPRS Int. J. Geo-Inf.* **8**, 321 (2019). https://doi.org/10.3390/ijgi8080321.
