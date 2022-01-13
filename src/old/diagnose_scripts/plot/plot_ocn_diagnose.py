import Ngl, Nio
import sys
import numpy as np

nc_file = sys.argv[1]
grid_file = sys.argv[2]

f = Nio.open_file(nc_file, "r")
g = Nio.open_file(grid_file, "r")

lon = g.variables["lon"][:]                   #-- read clon
lat = g.variables["lat"][:]                   #-- read clat

data = np.mean(f.variables["TREFHT"][:], axis=0) - 273.15


wks_type = "png"
wks = Ngl.open_wks(wks_type,"newcolor1")

cnres                 = Ngl.Resources()

# Contour resources
cnres.cnFillOn        = True
cnres.cnFillPalette   = "BlueYellowRed"      # New in PyNGL 1.5.0
cnres.cnLinesOn       = False
cnres.cnLineLabelsOn  = False

# Labelbar resource
cnres.lbOrientation   = "horizontal"

# Scalar field resources
cnres.sfXArray        = lon
cnres.sfYArray        = lat

# Map resources
cnres.mpFillOn               = True
cnres.mpFillDrawOrder        = "PostDraw"
cnres.mpLandFillColor        = "Gray"
cnres.mpOceanFillColor       = "Transparent"
cnres.mpInlandWaterFillColor = "Transparent"

contour = Ngl.contour_map(wks, data, cnres)

Ngl.end()




