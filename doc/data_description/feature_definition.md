# Feature

The following table provides an overview of independent features to be used in the landslide susceptibility model:

| variable                                            | abbreviation       | tool /source | topic        |
| --------------------------------------------------- | ------------------ | ------------ | ------------ |
| Antecedent Precipitation Index                      | API                | SPARTACUS    | climate      |
| Aspect                                              | aspect             | `gdaldem`    | morphometry  |
| Consecutive Wet Days                                | CWD                | SPARTACUS    | climate      |
| Convergence Index                                   | convergence_index  | SAGAGIS      | morphometry  |
| Terrain Surface Convexity                           | convexity          | SAGAGIS      | morphometry  |
| Curvature (max)                                     | curv_max           | SAGAGIS      | morphometry  |
| Curvature (min)                                     | curv_min           | SAGAGIS      | morphometry  |
| Curvature (plan)                                    | curv_plan          | SAGAGIS      | morphometry  |
| Curvature (profile)                                 | curv_prof          | SAGAGIS      | morphometry  |
| Diurnal Anisotropic Heat                            | DAH                | SAGAGIS      | morphometry  |
| Forest Cover                                        | forest             | BfW          | vegetation   |
| Geomorphons                                         | geomorphons        | SAGAGIS      | lighting     |
| Land Cover                                          | landcover          | Corine       | vegetation   |
| Maximum Height                                      | maximum_height     | SAGAGIS      | hydrology    |
| Melton Roughness Number                             | MRN                | SAGAGIS      | hydrology    |
| Lithology                                           | lithology          | geology      | geology      |
| Negative Topographic Openness                       | NTO                | SAGAGIS      | lighting     |
| Precipitation Concentration index                   | PCI                | SPARTACUS    | climate      |
| Positive Topographic Openness                       | PTO                | SAGAGIS      | lighting     |
| Distance to roads                                   | road_distance      | GIP          | road         |
| Roughness                                           | roughness          | `gdaldem`    | morphometry  |
| Heavy Rainfall Days                                 | RR_90q             | SPARTACUS    | climate      |
| Simple Precipitation Intensity Index                | SDII               | SPARTACUS    | climate      |
| Slope                                               | slope              | `gdaldem`    | morphometry  |
| Slope water                                         | slope_water        | hydrography  | hydrology    |
| Standardized Precipitation Evapotranspiration Index | SPEI_30            | WINFORE      | climate      |
| Stream Power Index                                  | SPI                | SAGAGIS      | hydrology    |
| Sky View Factor                                     | SVF                | SAGAGIS      | lighting     |
| Daily Precipitation Totals                          | precip_d           | SPARTACUS    | climate      |
| Topographic Position Index                          | TRI                | `gdaldem`    | morphometry  |
| Topographic Roughness Index                         | TRI                | `gdaldem`    | morphometry  |
| Topographic Wetness Index                           | TWI                | SAGAGIS      | hydrology    |
| Vector Ruggedness Measure                           | VRM                | SAGAGIS      | morphometry  |
| Distance to water bodies                            | water_distance     | hydrography  | hydrology    |

Notes:
- GIS-Tools for computing geomorphometric indicators from DEMs include [`gdaldem`](https://gdal.org/programs/gdaldem.html), [SAGA GIS](https://saga-gis.sourceforge.io/saga_tool_doc/8.0.0/ta_morphometry.html), [GRASS GIS](https://grass.osgeo.org/grass82/manuals/keywords.html#terrain%20patterns) and [WhiteBoxTools](https://www.whiteboxgeo.com/manual/wbt_book/available_tools/geomorphometric_analysis.html).
- Spatial resolution needs to be determined
- Climate indices need to be aggregated from annual data to a climatology using sensible aggregation functions (probably some high quantile)
