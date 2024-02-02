# Feature

The following table provides an overview of independent features to be used in the landslide susceptibility model:

| variable                                            | abbreviation       | tool /source | topic        |
| --------------------------------------------------- | ------------------ | ------------ | ------------ |
| Antecedent Precipitation Index (7 days)             | api_k7             | SPARTACUS    | climate      |
| Antecedent Precipitation Index (30 days)            | api_k30            | SPARTACUS    | climate      |
| Aspect                                              | aspect_acrctan2    | `gdaldem`    | morphometry  |
| Convergence Index                                   | convergence_index  | SAGAGIS      | morphometry  |
| Terrain Surface Convexity                           | convexity          | SAGAGIS      | morphometry  |
| Curvature (max)                                     | curv_max           | SAGAGIS      | morphometry  |
| Curvature (min)                                     | curv_min           | SAGAGIS      | morphometry  |
| Curvature (plan)                                    | curv_plan          | SAGAGIS      | morphometry  |
| Curvature (profile)                                 | curv_prof          | SAGAGIS      | morphometry  |
| Consecutive Wet Days                                | cwd                | SPARTACUS    | climate      |
| Diurnal Anisotropic Heat                            | dah                | SAGAGIS      | morphometry  |
| (Elevation)                                         | elevation          | DTM AT       | morphometry  |
| Effectively Surveyed Area                           | esa                | GRASS GIS    | inventory    |
| Flow Accumulation                                   | flow_accumulation  | SAGAGIS      | morphometry  |
| (Flow Path Length)                                  | flow_path_length   | SAGAGIS      | morphometry  |
| (Flow Width)                                        | flow_width         | SAGAGIS      | morphometry  |
| Forest Cover                                        | forest_cover       | BfW          | vegetation   |
| Geomorphons                                         | geomorphons        | SAGAGIS      | lighting     |
| Land Cover                                          | land_cover         | CadasterENV  | vegetation   |
| Lithology                                           | lithology          | GBA          | geology      |
| Maximum Height                                      | maximum_height     | SAGAGIS      | hydrology    |
| Melton Roughness Number                             | mrn                | SAGAGIS      | hydrology    |
| Negative Topographic Openness                       | nto                | SAGAGIS      | lighting     |
| Precipitation Concentration index                   | pci                | SPARTACUS    | climate      |
| Precipitation Totals                                | prcptot            | SPARTACUS    | climate      |
| Positive Topographic Openness                       | pto                | SAGAGIS      | lighting     |
| Distance to roads                                   | road_dist          | GIP          | road         |
| Roughness                                           | roughness          | `gdaldem`    | morphometry  |
| Maximum 1 Day Precipitation                         | rx1day             | SPARTACUS    | climate      |
| Maximum 5 Day Precipitation                         | rx5day             | SPARTACUS    | climate      |
| Specific Catchment Area                             | sca                | SAGAGIS      | morphometry  |
| Simple Precipitation Intensity Index                | sdii               | SPARTACUS    | climate      |
| Slope                                               | slope              | `gdaldem`    | morphometry  |
| Standardized Precipitation Evapotranspiration Index | spei_30            | WINFORE      | climate      |
| Stream Power Index                                  | spi                | SAGAGIS      | hydrology    |
| Sky View Factor                                     | svf                | SAGAGIS      | lighting     |
| Slope water: Hazard Category                        | sw_hazard_cat      | hydrography  | hydrology    |
| Slope water: Maximum Depth                          | sw_max_depth       | hydrography  | hydrology    |
| Slope water: Maximum Speed                          | sw_max_speed       | hydrography  | hydrology    |
| Slope water: Specific Runoff                        | sw_spec_runoff     | hydrography  | hydrology    |
| Topographic Position Index                          | tpi                | `gdaldem`    | morphometry  |
| Topographic Roughness Index                         | tri                | `gdaldem`    | morphometry  |
| Topographic Wetness Index                           | twi                | SAGAGIS      | hydrology    |
| Vector Ruggedness Measure                           | vrm                | SAGAGIS      | morphometry  |
| Wind Exposition Index                               | wei                | SAGAGIS      | morphometry  |

Notes:
- GIS-Tools for computing geomorphometric indicators from DEMs include [`gdaldem`](https://gdal.org/programs/gdaldem.html), [SAGA GIS](https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry.html), [GRASS GIS](https://grass.osgeo.org/grass82/manuals/keywords.html#terrain%20patterns) and [WhiteBoxTools](https://www.whiteboxgeo.com/manual/wbt_book/available_tools/geomorphometric_analysis.html).
- Spatial resolution needs to be determined
- Climate indices need to be aggregated from annual data to a climatology using sensible aggregation functions (probably some high quantile)
