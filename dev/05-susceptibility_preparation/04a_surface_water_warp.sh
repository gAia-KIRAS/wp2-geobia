#!/usr/bin/zsh

cd dat
unzip raw/oberflaechenabfluss/KTN_Gefahrenkategorien.zip -d interim/oberflaechenabfluss/orig/
7z e raw/oberflaechenabfluss/KTN_MaxWassertiefe.zip -ointerim/oberflaechenabfluss/orig/
7z e raw/oberflaechenabfluss/KTN_MaxGeschwindigkeit.zip -ointerim/oberflaechenabfluss/orig/
7z e raw/oberflaechenabfluss/KTN_SpezifischerAbfluss.zip -ointerim/oberflaechenabfluss/orig/

for intiff in ./interim/oberflaechenabfluss/orig/*tif;
do
  echo "$(date +'%T') » Working on $intiff:t"
  outtiff="./interim/oberflaechenabfluss/prep/$intiff:t"
  gdalwarp -s_srs EPSG:31258 -t_srs EPSG:3416 \
    -tr 10 -10 -r max \
    -te 348655 300975 532535 359205 \
    $intiff $outtiff
done
