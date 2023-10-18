# KAGIS

## Point data

 Attempt at documenting the KAGIS-export `Massenbewegungen_im_Detail.shp` obtained on 2023-10-04

| column name | description                                    |
| ----------- | ---------------------------------------------- |
| OBJEKTID    | some id                                        |
| WIS_ID      | some other id                                  |
| ANL_NAME    | name of entry?                                 |
| ANL_TYPE    | type of entry short - only "EREIG"             |
| ANL_TYPE_N  | type of entry long  - only "Ereigniskataster"  |
| ANL_SUBTYP  | event subtype? - only "Massenbewegung"         |
| ANL_BEARBS  | could be processing state (Bearbeitungsstatus) |
| ANL_VORT_Q  | could be geological map used for mapping?      |
| ROOT_ANL_N  | largely a duplicate of ANL_NAME                |
| ROOT_ANL_I  | duplicate of WIS_ID                            |
| GEW_NAME    | name of municipality, incomplete               |
| SPRT_NAME   | unclear, only "Massenbewegungen gesamt"        |
| OBJECTID    | yet another id                                 |
| ANL_BEAR_1  | no idea, but probably not related to bears 🐻 |
| ANL_SUBT_1  | no idea - only "S4002299"                      |
| ANL_SPRT_I  | no idea - only "S4003556"                      |
| ANL_VORT_X  | no idea                                        |
| ANL_NAME2   | no idea, some code                             |
| EREIG_ZEIT  | event timestamp                                |
| ERH_ZEIT    | documentation timestamp                        |
| TYP         | process type (unclean)                         |
| TYP_CODE    | process type (clean)                           |
| AKT_DATE    | date of latest update                          |
| geometry    | geometry                                       |


## Process types

> Column: TYP_CODE

| type             |   n |
| ---------------- | --- |
| Bergsturz        |   1 |
| Blocksturz       | 163 |
| Erdfall          |  22 |
| Erdstrom         | 337 |
| Felssturz        |  82 |
| Mure             |  13 |
| Rutschung gross  | 330 |
| Rutschung klein  | 917 |
| Rutschung mittel | 493 |
| Schuttstrom      |  44 |
| Steinschlag      | 300 |

## Polygon data

> Attempt at documenting the KAGIS-export `Rutschungsflaechen.shp` obtained on 2023-10-04

| column name | description                                                                 |
| ----------- | --------------------------------------------------------------------------- |
| OBJECTID    | some id                                                                     |
| POLYGON_ID  | another id                                                                  |
| POLYGON_NA  | polygon name                                                                |
| FK_GEBIET_  | could be related to collection method, Geolantis (389), Nacherfassung (103) |
| BEARBEITER  | name of geologist recording the entry                                       |
| DATUM_VON   | event daterange start                                                       |
| DATUM_BIS   | event daterange end                                                         |
| YEAR        | event year                                                                  |
| TRANSFER_D  | no idea                                                                     |
| DATUM_ARCH  | no idea                                                                     |
| STATUS_INT  | processing status                                                           |
| INTRAMAP_B  | weird stuff                                                                 |
| INTRAMAP_1  | empty                                                                       |
| FOTO_LINK   | internal link to photo of event                                             |
| CREATE_DAT  | creation date                                                               |
| UPDATE_DAT  | update date                                                                 |
| ORIGINAL_N  | no idea                                                                     |
| PROJEKT     | mapping project / campaign?                                                 |
| KATEGORIE   | some broad category, Gesamt (461), Ablagerung (13), Anriss (18)             |
| SHAPE_AREA  | area of the polygon                                                         |
| SHAPE_LEN   | circumference of the polygon                                                |
| geometry    | polygon geometry                                                            |
