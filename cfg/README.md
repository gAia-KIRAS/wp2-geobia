# Configuration

## Conda environments
*Note: all environments are exported without build specification (i.e. `conda env export --no-builds > environment.yml`)*

1. `grass_script`:
    - DTM preprocessing using GRASS GIS wrappers
    - `conda env create -f grass_script.yml`
    - Core setup:
    ```sh
    conda create --name grass_script
    conda install -c conda-forge python pip ipython numpy pandas gdal black
    pip install grass-session
    ```

## Config files
- `aoi_config.sh`: shell configuration settings
