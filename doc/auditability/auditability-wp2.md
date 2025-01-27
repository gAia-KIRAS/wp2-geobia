## gAia Auditability Overview WP 2 

> Location: online  
> Date, Time: tba  
> Participants:
> - [Geosphere] Matthias Schlögl (MSch)
> - [Geosphere] Michael Avian (MA)
> - [SBA] Rudolf Mayer (RM)
> - [SBA] Tomasz Miksa (TMi)
> - [SBA] Laura Waltersdorfer (LW)


## General
- LW: short intro on WP 6/auditability
    - T6.1: definition of data management plan
    - description of questionnaire
- Geosphere: Overview of WP task and current process
    - going through questionnaire


## 1) General

- **General current description of the task solved by the WP and connection to the other WPs (main components, data flows, processing steps, inputs and outputs, supporting services/libraries)?**
    - TODO @mavian
- **What would be the outputs(s) of the WP? (e.g.: ML model, datasets, application, results,....)**
    - model: GEOBIA-model for automated delineation of landslide polygons from VHR ALS DTM data
    - dataset: comprehensive inventory of landslides present at the time of DTM generation
- **Who are the main stakeholders of the designed system from your point of view? (creators, users, involved/affected parties,...)**
    - TODO @mavian
- **What will be the main activities of the WP/system? (e.g processing steps, components)**
    - TODO @mavian


## 2) Input

> transparency of training data and limitations

- **What kind of data do you use? (TMi sheet)**
    - **input format/needs**
    - **source**
    - **storage**
        - **custom created dataset**
            - **data collection process**
        - **already existing/reused dataset**: ALS DTM, existing inventories
            - **creator/supplier**
            - **version**
            - **original use of dataset**
            - **funding**
            - **license**
    - **annotation process (if applicable)**
    - **data cleaning process (if applicable)**
        - **steps**
            - DTM: fill sinks
            - inventory: filter relevant process categories
    - **sample size**
    - **limitations/bias in the data**:
        - DTM: age (potentially out-of-date), inconsistent timestamps
        - inventory: location and timestamp potentially uncertain; location might be only point instead of polygon, time might be inaccurate or missing completely 
    - **size, proportion or distribution of training data**


## 3) Output

> explaining output

- **What kind of output does the system produce?**
    - **scope of system/function capability**
    - **format**
    - **how is the output used by other components**
    - **how should it be best utilized?**
    - **necessary capabilities/skills to interpret output (specific skills needed?)**
    - **same questions as input (license,..)**


## 4) (ML) Model or also Software (if applicable)

- **parameters**
- **reused libraries**
- **software version**
- **hyperparameters**
- **algorithms**
- **evaluation specification**
- **evaluation procedure**
    - **results**
    - **process steps**
    - **evaluators**
    - **metrics**
- **licence**
