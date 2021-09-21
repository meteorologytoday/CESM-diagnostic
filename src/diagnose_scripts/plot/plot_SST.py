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
parser.add_argument('--data-file', dest='data_file')
#parser.add_argument('--data-file-SSTAVAR', dest='SSTAVAR_file')
parser.add_argument('--domain-file', dest='domain_file')
parser.add_argument('--output-dir', dest='output_dir')
parser.add_argument('--casename', dest='casename')

args = parser.parse_args()

f = Nio.open_file(args.data_file, "r")
g = Nio.open_file(args.domain_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat


data = np.mean(f.variables["TREFHT"][:], axis=0) - 273.15

f.close()

lon = ext_axis(lon)
data = ext(data)


wks_type = "png"
wks = Ngl.open_wks(wks_type, "%s/%s_atm_SST" % (args.output_dir, args.casename))

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
cnres.mpCenterLonF = 200.0

cnres.tiMainFontHeightF = 0.01
cnres.tiMainString         = "[%s] SST" % (args.casename,)

contour = Ngl.contour_map(wks, data, cnres)

Ngl.end()




