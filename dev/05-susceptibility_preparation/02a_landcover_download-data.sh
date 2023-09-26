#!/usr/bin/zsh

# Hochgenaue Waldkarte
wget https://bfwwebm.bfw.ac.at/nextcloud/index.php/s/4S9Gp3DDAY58jHH/download -O wk.zip
mv wk.zip dat/raw/waldkarte/
unzip wk.zip
rm wk.zip
unrar e wk_austria_10m_202302_TIF.rar

gdalwarp -tr 10 -10 -tap -t_srs EPSG:3416 \
  -te 348655 300975 532535 359205 \
  dat/raw/waldkarte/wk_austria_10m_202302.tif dat/interim/misc_aoi/wk_aoi_ktn.tif

# Corine Land Cover
wget https://docs.umweltbundesamt.at/s/beBw8fmwyCMA2ga/download/CLC_2018_AT_clip.zip
mv CLC_2018_AT_clip.zip dat/raw/clc/
unzip CLC_2018_AT_clip.zip
rm CLC_2018_AT_clip.zip

# cadasterENV
# https://landmonitoring.earth/portal/

gdalwarp -tr 10 -10 -tap -t_srs EPSG:3416 \
  -te 348655 300975 532535 359205 \
  dat/raw/cadasterENV/FP_P1_HR_LandCoverMap2016_L2.tif dat/interim/misc_aoi/cadasterenv_ktn.tif
