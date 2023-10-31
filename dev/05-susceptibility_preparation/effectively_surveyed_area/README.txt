This program was developed by:

Ivan Marchesini
Research Institute for Geo-Hydrological Protection
via Madonna Alta, 126 - 06128 - Perugia, Italy
ivan.marchesini@irpi.cnr.it

This program is free software under the GNU General Public
License (>=v2). Read the file COPYING that comes with GRASS
for details.

It was designed and tested for use under Linux and GRASS GIS [v7.4].

Please make sure that the r.survey.py file is executable before
attempting to use it. If not, grant execution privileges to the
file, i.e. run:

chmod +x r.survey.py

The software should be moved into the scripts folder of the GRASS
GIS installation, typically /usr/lib/grass[v7.4]/scripts.

Details about the input parameters, can be obtained running the following command within a GRASS GIS shell:

r.survey.py --h

If the software is not copied in the GRASS GIS script folder, it can be used  from command line:

./r.survey.py

The inputs are the following (all of them are required):

- points : name of input (vector) points map
- dem    : name of input (raster) DEM map
- output : prefix for the output (raster) maps
- maxdist: max visibility distance, in meters. Default: 1000 m

The outputs are: 
"prefix+"_viewangles, i.e. the map of the higher angle the single cell is visible from the different points (the closer the angle is to 180 degrees the more the point is in front of the cell and the cell is therefore very well visible) 
"prefix+"_numberofviews, i.e. the map of the number of points from which the single cell is visible from
"prefix+"_pointofviews, i.e. the map of the point from which the single cell is better visible
"prefix+"_distance_rescaled, i.e. the best map of the a "rescaled distance" of the cell from the different points (it is a sort of index combining distance and angle of view)


