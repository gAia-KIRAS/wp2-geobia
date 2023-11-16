# Landslide inventory - conceptual structure

> Format: GeoPackage

- `landslide_inventory` [point]
  | name                | description                                                | data type        |
  | ------------------- | ---------------------------------------------------------- | ---------------- |
  | `id`                | unique id of event                                         | integer          |
  | `process_type`      | process type of event                                      | integer (factor) |
  | `event_date`        | date of event occurrence                                   | integer (date)   |
  | `source`            | source dataset (e.g. kagis, georios, etc.)                 | integer (factor) |
  | `source_id`         | id from source dataset                                     | character?       |
  | `collection_method` | type of event collection (orthophoto, field mapping, news) | integer (factor) |
  | `quality_loc`       | qualitative assessment of location accuracy                | integer (factor) |
  | `last_update`       | last update of the event entry                             | integer (date)   |
  | `modified`          | has the entry been modified w.r.t. the original inventory  | logiacl          |
  | `geom`              | simple feature geometry in defined CRS                     | geometry         |
- `process_type` [table]: lookup-table for process type
- `source` [table]: lookup-table for dataset source
- `source_id_col` [table]: lookup-table for column name of source-id per source-dataset
- `quality_loc` [table]: lookup-table for location accuracy

