#!/usr/bin/bash

echo "Unzipping archive"
unzip dat/raw/inventory/GEORIOS_for_gAia.gdb.zip -d dat/interim/inventory/

echo "Converting gdb to gpkg"
ogr2ogr -f GPKG "dat/interim/inventory/GEORIOS_for_gAia.gpkg" "dat/interim/inventory/GEORIOS_for_gAia.gdb" GEORIOS_for_gAia_final

echo "Cleaning up"
cd dat/interim/inventory/
rm -r GEORIOS_for_gAia.gdb
cd -

echo "Done"
