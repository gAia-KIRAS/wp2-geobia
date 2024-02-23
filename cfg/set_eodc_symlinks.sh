#!/usr/bin/zsh

cd dat
ln -sf /eodc/private/zamg/proj/eogis/gaia/data/processed
ln -sf /eodc/private/zamg/proj/eogis/gaia/data/reporting

cd raw
ln -sf /eodc/private/zamg/proj/eogis/gaia/data/raw/aoi

cd ../interim
ln -sf /eodc/private/zamg/proj/eogis/gaia/data/interim/dtm_aoi
ln -sf /eodc/private/zamg/proj/eogis/gaia/data/interim/dtm_derivates
ln -sf /eodc/private/zamg/proj/eogis/gaia/data/interim/misc_aoi

cd ...

echo "Symlinks updated"
