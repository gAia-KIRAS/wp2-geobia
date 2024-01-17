#!/usr/bin/env python
#
############################################################################
#
# MODULE:    r.survey
# AUTHOR(S): Ivan Marchesini
# PURPOSE:   Define visible area from survey sites
#
# COPYRIGHT: (C) 2014 by Ivan Marchesini
#
#   This program is free software under the GNU General Public
#   License (>=v2). Read the file COPYING that comes with GRASS
#   for details.
#
#############################################################################

#%Module
#% description: map visible areas during field survey
#% keywords: visibility
#% keywords: survey
#%end
#%option G_OPT_V_POINTS
#% key: points
#% description: Name of the input points layer (representing the field survey path)
#% required: yes
#%end
#%option G_OPT_R_DEM
#% key: dem
#% description: Name of the input DEM layer
#% required: yes
#%end
#%option G_OPT_R_OUTPUT
#% key: output
#% description: Prefix for the output visibility layers
#% required: yes
#%end
#%option
#% key: maxdist
#% type: double
#% description: max distance from the input points
#% required: yes
#% answer: 1000
#%end

import sys
from grass_session import Session
import grass.script as grass
from grass.script import core as grasscore


def main():
    pnt = options["points"]
    dem = options["dem"]
    output = options["output"]
    maxdist = float(options["maxdist"])

    # save the current working region
    grass.run_command("g.region", save="saved_region", overwrite=True)
    # to do: a control for creating, only inside the study area, the aspect and the slope layers, could be added
    grass.run_command(
        "r.slope.aspect",
        elevation=dem,
        slope="slope",
        aspect="aspect",
        overwrite=True,
        quiet=True,
    )
    # evaluation of the azimuth layer
    grass.mapcalc(
        "azimuth = (450-aspect) - int( (450-aspect) / 360) * 360",
        overwrite=True,
        quiet=True,
    )
    # evaluation of the layer of the vertical component of the versor perpendicular to the terrain slope
    grass.mapcalc("c_dem = cos(slope)", overwrite=True, quiet=True)
    # evaluation of the layer of the north component of the versor perpendicular to the terrain slope
    grass.mapcalc("b_dem = sin(slope)*cos(azimuth)", overwrite=True, quiet=True)
    # evaluation of the layer of the east component of the versor perpendicular to the terrain slope
    grass.mapcalc("a_dem = sin(slope)*sin(azimuth)", overwrite=True, quiet=True)

    # creating a list of the available points in the input layer
    npnt = int(grass.vector_info_topo(pnt)["points"])
    ctg = grass.read_command(
        "v.category", flags="g", input=pnt, option="print", type="point"
    )
    ctg = ctg.split("\n")
    # removing last empy element of the list
    ctg.pop(-1)

    # creating some empty (0) raster layers
    grass.mapcalc("xxtemp = 0", overwrite=True, quiet=True)
    grass.mapcalc("xxtemp2 = 0", overwrite=True, quiet=True)
    grass.mapcalc("xxtemp3 = 0", overwrite=True, quiet=True)
    grass.mapcalc("xxtemp4 = 0", overwrite=True, quiet=True)

    # starting the main loop for each point in the point input layer
    k = 0
    for i in ctg:
        k = k + 1
        message = """
        --------------------------------------
        ----------- running point %s (cat = %s) of %s points --
        --------------------------------------
        """
        grass.message(message % (k, i, npnt))
        # extracting a point
        grass.run_command(
            "v.extract", input=pnt, output="pnt", cat=i, overwrite=True, quiet=True
        )
        coords = grass.read_command(
            "v.to.db",
            flags="p",
            map="pnt",
            type="point",
            option="coor",
            separator="|",
            quiet=True,
        )
        x = float(coords.split("|")[1])
        y = float(coords.split("|")[2])
        coords = str(x) + "," + str(y)
        # getting point elevation
        querydem = grass.read_command("r.what", coordinates=coords, map=dem)
        obselev = float(querydem.split("|")[3])
        # setting the working region around the point
        grass.run_command("g.region", vect="pnt")
        region = grasscore.region()
        E = region["e"]
        W = region["w"]
        N = region["n"]
        S = region["s"]
        grass.run_command(
            "g.region",
            flags="a",
            e=E + maxdist,
            w=W - maxdist,
            s=S - maxdist,
            n=N + maxdist,
        )
        # running visibility analysis
        grass.run_command(
            "r.viewshed",
            input=dem,
            output="view",
            coordinates=coords,
            max_dist=maxdist,
            memory=5000,
            overwrite=True,
            quiet=True,
        )
        # coming back to the original working region
        grass.run_command("g.region", region="saved_region")
        # Since r.viewshed set the cell of the output visibility layer to 180 under the point, this cell is set to 0.01
        grass.mapcalc("view = if(view==180,0.01,view)", overwrite=True, quiet=True)
        # estimating the layer of the horizontal angle between point and each visible cell (angle of the horizontal line of sight)
        grass.mapcalc(
            "${A} = \
            if( y()>${py} && x()>${px}, atan((${px}-x())/(${py}-y())),  \
            if( y()<${py} && x()>${px}, 180+atan((${px}-x())/(${py}-y())),  \
            if( y()<${py} && x()<${px}, 180+atan((${px}-x())/(${py}-y())),  \
            if( y()>${py} && x()<${px}, 360+atan((${px}-x())/(${py}-y())))      )      )    )",
            A="angolo_vista",
            py=y,
            px=x,
            overwrite=True,
            quiet=True,
        )
        # estimating the layer of the vertical angle between point and each visible cell  (angle of the vertical line of sight)
        grass.mapcalc("view90 = view - 90", overwrite=True, quiet=True)
        # evaluate the vertical component of the versor oriented along the line of sight
        grass.mapcalc("c_view = sin(view90)", overwrite=True, quiet=True)
        # evaluate the northern component of the versor oriented along the line of sight
        grass.mapcalc(
            "b_view = cos(view90)*cos(angolo_vista)", overwrite=True, quiet=True
        )
        # evaluate the eastern component of the versor oriented along the line of sight
        grass.mapcalc(
            "a_view = cos(view90)*sin(angolo_vista)", overwrite=True, quiet=True
        )
        # estimate the three-dimensional distance between the point and each visible cell
        grass.mapcalc(
            "${D} = pow(pow(abs(y()-${py}),2)+pow(abs(x()-${px}),2)+pow(abs(${dtm}-(${obs}+1.75)),2),0.5)",
            D="distance",
            dtm=dem,
            obs=obselev,
            py=y,
            px=x,
            overwrite=True,
            quiet=True,
        )
        # estimating the layer of the angle between the versor of the terrain and the line of sight
        grass.mapcalc(
            "angle = acos((a_view*a_dem+b_view*b_dem+c_view*c_dem)/(sqrt(a_view*a_view+b_view*b_view+c_view*c_view)*sqrt(a_dem*a_dem+b_dem*b_dem+c_dem*c_dem)))",
            overwrite=True,
            quiet=True,
        )
        # evaluating the layer of the distance scaled by the cosine of the angle
        grass.mapcalc(
            "dist_rescaled = if(angle>91,(distance/(-cos(angle))),null())",
            overwrite=True,
            quiet=True,
        )
        # setting all the null cells to zero
        grass.run_command("r.null", map="angle", null=0, quiet=True)

        # updating the output layer of the rescaled distance
        grass.mapcalc(
            "xxtemp4 = if(isnull(dist_rescaled),xxtemp4, if(xxtemp4 != 0,min(dist_rescaled,xxtemp4),dist_rescaled))",
            overwrite=True,
            quiet=True,
        )
        # updating the output layer of the category of the point who has the higher angles with the considered cell
        grass.mapcalc(
            "xxtemp3 = if(angle==0,xxtemp3, if(angle<xxtemp,xxtemp3,${cat}) ) ",
            cat=i,
            overwrite=True,
            quiet=True,
        )
        # updating the output layer of the number of points from which a cell is visible
        grass.mapcalc(
            "xxtemp2 = if(angle==0,xxtemp2,xxtemp2+1)", overwrite=True, quiet=True
        )
        # updating the output layer of the best angle of view among all the points in the path
        grass.mapcalc("xxtemp = max(xxtemp,angle)", overwrite=True, quiet=True)

    # creating the output layer
    grass.run_command("r.null", map="xxtemp", setnull=0, quiet=True, overwrite=True)
    grass.run_command("r.null", map="xxtemp2", setnull=0, quiet=True, overwrite=True)
    grass.run_command("r.null", map="xxtemp3", setnull=0, quiet=True, overwrite=True)
    grass.run_command("r.null", map="xxtemp4", setnull=0, quiet=True, overwrite=True)
    grass.run_command(
        "g.copy", rast=("xxtemp", output + "_viewangles"), quiet=True, overwrite=True
    )
    grass.run_command(
        "g.copy",
        rast=("xxtemp2", output + "_numberofviews"),
        quiet=True,
        overwrite=True,
    )
    grass.run_command(
        "g.copy", rast=("xxtemp3", output + "_pointofviews"), quiet=True, overwrite=True
    )
    grass.run_command(
        "g.copy",
        rast=("xxtemp4", output + "_distance_rescaled"),
        quiet=True,
        overwrite=True,
    )

    # removing the temporary layers
    grass.run_command("g.remove", type="vector", name="pnt", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="xxtemp", quiet=True, flags="f")
    grass.run_command(
        "g.remove", type="raster", name="angolo_vista", quiet=True, flags="f"
    )
    grass.run_command("g.remove", type="raster", name="slope", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="aspect", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="azimuth", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="c_dem", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="b_dem", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="a_dem", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="view90", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="c_view", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="b_view", quiet=True, flags="f")
    grass.run_command("g.remove", type="raster", name="a_view", quiet=True, flags="f")


if __name__ == "__main__":
    options, flags = grass.parser()
    sys.exit(main())
