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
