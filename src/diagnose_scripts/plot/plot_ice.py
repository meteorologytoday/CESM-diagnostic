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
parser.add_argument('--data-file')
parser.add_argument('--domain-file')
parser.add_argument('--output-dir')
parser.add_argument('--casename')
parser.add_argument('--selected-month', type=int)

args = parser.parse_args()

print(str(args))

selected_month = args.selected_month

g = Nio.open_file(args.domain_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat

lon = ext_axis(lon)

print(lon)
f = Nio.open_file(args.data_file, "r")
data = f.variables["aice_MA"][selected_month-1, :, :] * 100.0
missing_value = f.variables["aice_MA"]._FillValue[0]
data[np.isnan(data)] = missing_value

data = ext(data)
f.close()

print("Creating workstation...")

wks_type = "png"
wks      =  Ngl.open_wks(wks_type, "%s/%s-aice-%02d" % (args.output_dir, args.casename, selected_month)) #-- open a workstation

print("Defining res...")
cnres                 = Ngl.Resources()

cnres.sfMissingValueV = missing_value

cnres.tiMainFontHeightF = 0.01
cnres.tiMainString = "[%s] Sea-ice concentration of month %d" % (args.casename, selected_month)


# Contour resources
cnres.cnFillOn        = True
cnres.cnFillPalette   = "cmocean_tempo"
cnres.cnLinesOn       = False
cnres.cnLineLabelsOn  = False

cnres.cnLevelSelectionMode = "ManualLevels"
cnres.cnMaxLevelValF  =   100.0
cnres.cnMinLevelValF  =   10.0
cnres.cnLevelSpacingF =  10.0


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
#Ngl.end()
print("plotting done.")

