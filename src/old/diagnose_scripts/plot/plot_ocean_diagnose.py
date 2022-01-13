import Ngl, Nio
import sys, argparse
import numpy as np


def ext(data):
    s = data.shape
    ndata = np.zeros((s[0], s[1]+1))
    ndata[:, 0:-1] = data
    ndata[:, -1] = data[:, 0]
    return ndata
 

def ext_axis(lon):
    return np.append(lon, 360) 
    

parser = argparse.ArgumentParser()
parser.add_argument('--data-file-SSTAYYC', dest='SSTAYYC_file')
parser.add_argument('--data-file-SSTAVAR', dest='SSTAVAR_file')
parser.add_argument('--domain-file', dest='domain_file')
parser.add_argument('--output-dir', dest='output_dir')
parser.add_argument('--casename', dest='casename')
parser.add_argument('--selected-month', type=int)

args = parser.parse_args()

print(str(args))

selected_month = args.selected_month

g = Nio.open_file(args.domain_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat

lon = ext_axis(lon)

print(lon)
f = Nio.open_file(args.SSTAYYC_file, "r")
data = f.variables["SSTAYYC"][selected_month-1, :, :]
missing_value = f.variables["SSTAYYC"]._FillValue[0]
data[np.isnan(data)] = missing_value

data = ext(data)
f.close()

print("Creating workstation...")

wks_type = "png"
wks      =  Ngl.open_wks(wks_type, "%s/%s-SSTAYYC-%02d" % (args.output_dir, args.casename, selected_month)) #-- open a workstation

print("Defining res...")
cnres                 = Ngl.Resources()

cnres.sfMissingValueV = missing_value

cnres.tiMainFontHeightF = 0.01
cnres.tiMainString = "[%s] SSTA year-to-year correlation of month %d" % (args.casename, selected_month)

# Contour resources
cnres.cnFillOn        = True
cnres.cnFillPalette   = "BlueYellowRed"      # New in PyNGL 1.5.0
cnres.cnLinesOn       = False
cnres.cnLineLabelsOn  = False

cnres.cnLevelSelectionMode = "ManualLevels"
cnres.cnMaxLevelValF  =   1.0
cnres.cnMinLevelValF  =  -1.0
cnres.cnLevelSpacingF =  0.2



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

cnres.mpCenterLonF = 200.0
"""
cnres.mpLimitMode = "LatLon"
cnres.mpMaxLonF = -190.0
cnres.mpMinLonF = 0.0
cnres.mpMaxLatF = 70.0
cnres.mpMinLatF = -90.0
"""

print("Start plotting...")
contour = Ngl.contour_map(wks, data, cnres)
#Ngl.end()
print("plotting done.")



# ================================================


f = Nio.open_file(args.SSTAVAR_file, "r")
data = f.variables["SSTAVAR"][selected_month-1, :, :]
missing_value = f.variables["SSTAVAR"]._FillValue[0]
data[np.isnan(data)] = missing_value
f.close()

print("Creating workstation...")

wks_type = "png"
wks      =  Ngl.open_wks(wks_type, "%s/%s-SSTAVAR-%02d" % (args.output_dir, args.casename, selected_month))

print("Defining res...")
cnres                 = Ngl.Resources()

cnres.sfMissingValueV = missing_value

cnres.tiMainFontHeightF = 0.01
cnres.tiMainString = "[%s] SSTA variance of month %d" % (args.casename, selected_month)

# Contour resources
cnres.cnFillOn        = True
cnres.cnFillPalette   = "BlueYellowRed"      # New in PyNGL 1.5.0
cnres.cnLinesOn       = False
cnres.cnLineLabelsOn  = False

cnres.cnLevelSelectionMode = "ManualLevels"
cnres.cnMaxLevelValF  =   2.0
cnres.cnMinLevelValF  =  -2.0
cnres.cnLevelSpacingF =  0.2


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

cnres.mpCenterLonF = 200.0

print("Start plotting...")
contour = Ngl.contour_map(wks, data, cnres)
Ngl.end()
print("plotting done.")
