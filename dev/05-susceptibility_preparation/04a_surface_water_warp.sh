#!/usr/bin/zsh

cd dat
unzip raw/oberflaechenabfluss/KTN_Gefahrenkategorien.zip -d interim/oberflaechenabfluss/orig/
7z e raw/oberflaechenabfluss/KTN_MaxWassertiefe.zip -ointerim/oberflaechenabfluss/orig/
7z e raw/oberflaechenabfluss/KTN_MaxGeschwindigkeit.zip -ointerim/oberflaechenabfluss/orig/
7z e raw/oberflaechenabfluss/KTN_SpezifischerAbfluss.zip -ointerim/oberflaechenabfluss/orig/

for intiff in ./interim/oberflaechenabfluss/orig/*tif;
do
  echo "Working on $intiff:t"
  outtiff="./interim/oberflaechenabfluss/prep/$intiff:t"
  gdalwarp -tr 10 -10 -r med -tap -t_srs EPSG:3416 \
    -te 348660 300970 532530 359210 \
    -cutline raw/aoi/gaia_projektgebiet_ktn.gpkg -cl gaia_projektgebiet -crop_to_cutline -of GTiff \
    $intiff $outtiff
done
