#!/usr/bin/zsh

wget https://docs.umweltbundesamt.at/s/YkgTDiDs9DPstCJ/download/Routen_v16.zip -P dat/raw/ggn/
unzip dat/raw/ggn/Routen_v16.zip -d dat/raw/ggn/
rm dat/raw/ggn/Routen_v16.zip..
