import Ngl, Nio
import sys
import numpy as np

nc_file = sys.argv[1]
grid_file = sys.argv[2]
output_dir = sys.argv[3]

f = Nio.open_file(nc_file, "r")
g = Nio.open_file(grid_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat

print(lon)
print(lat)

print("Getting Data")
data = f.variables["SSTAYYC"][11, :, :]
print(data.shape)
print("DONE")

data[:] = 0

#---Start the graphics
print("Start plotting...")

wks_type = "png"
wks = Ngl.open_wks(wks_type, "%s/SSTAYYC" % (output_dir,))

#---Read in desired color map so we can subset it later
cmap = Ngl.read_colormap_file("WhiteBlueGreenYellowRed")

res                      = Ngl.Resources()              # Plot mods desired.

res.cnFillOn             = True              # color plot desired
res.cnFillPalette        = cmap[48:208,:]    # Don't use white
res.cnLinesOn            = False             # turn off contour lines
res.cnLineLabelsOn       = False             # turn off contour labels
res.lbOrientation        = "Horizontal"      # vertical by default

res.trGridType           = "TriangularMesh"  # This is required to allow
                                             # missing coordinates.
res.cnLevelSelectionMode = "ManualLevels"
res.cnMinLevelValF       = 0.0
res.cnMaxLevelValF       = 1.0
res.cnLevelSpacingF      = 0.1
res.mpFillOn             = False
res.mpGridAndLimbOn      = False

res.sfXArray             = lon
res.sfYArray             = lat

res.cnFillMode           = "RasterFill"      # turn raster on      
res.tiMainString         = "[%s] SSTA Year to year correlation" % (args.casename,)
res.tiMainFontHeightF   = 0.018

plot = Ngl.contour_map(wks, data, res)  
#plot = Ngl.contour(wks, data, res)

print("End plotting...")

Ngl.end()




