# Configuration

## Conda environments
*Note: all environments are exported without build specification (i.e. `conda env export --no-builds > environment.yml`)*

1. `grass_script`:
    - DTM preprocessing using GRASS GIS wrappers
    - Used for `dev/01-dtm_preparation`
    - `conda env create -f grass_script.yml`
    - Core setup:
    ```sh
    conda create --name grass_script
    conda install -c conda-forge python pip ipython numpy pandas gdal black
    pip install grass-session
    ```

## Config file lists
- `vrt_list_dtm_noe.txt`: Paths of files used to construct the virtual raster for the DTM of Lower Austria


## Config files
- `aoi_config.sh`: shell configuration settings

## R Setup
- `ubuntu_r_setup.sh`: install system dependencies
- `install_packages.R`: install required R packages