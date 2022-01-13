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

parser.add_argument('--varname')
parser.add_argument('--title', default="")
parser.add_argument('--colormap')
parser.add_argument('--auto-clevs', action="store_true", default=False)
parser.add_argument('--cmin', type=float)
parser.add_argument('--cmax', type=float)
parser.add_argument('--clevs', type=int)
parser.add_argument('--clabel', default="")
parser.add_argument('--offset', type=float, default=0.0)
parser.add_argument('--scale', default="1.0")
parser.add_argument('--idx-t', type=int, default=-1)
parser.add_argument('--idx-z', type=int, default=-1)
parser.add_argument('--extra-filename', default="")
parser.add_argument('--land-transparent', action="store_true", default=False)


args = parser.parse_args()

f = Nio.open_file(args.data_file, "r")
g = Nio.open_file(args.domain_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat

args.scale = eval(args.scale)

var = f.variables[args.varname]
if args.idx_t == -1:
    if args.idx_z == -1:
        data = var[:, :]
    else:
        data = var[args.idx_z, :, :]
else:
    if args.idx_z == -1:
        data = var[args.idx_t, :, :]
    else:
        data = var[args.idx_t, args.idx_z, :, :]
 

       
data -= args.offset
data /= args.scale

missing_value = var._FillValue[0] 
data[np.isnan(data)] = missing_value

f.close()


# Extend data to avoid a white stripe on the 0-deg lon
lon = ext_axis(lon)
data = ext(data)


wks_type = "png"
wks = Ngl.open_wks(wks_type, "%s/%s_contourf_%s%s" % (args.output_dir, args.casename, args.varname, args.extra_filename))

cnres                 = Ngl.Resources()

# Contour resources
cnres.cnFillOn        = True
cnres.cnFillPalette   = Ngl.read_colormap_file(args.colormap)
#cnres.cnFillPalette   = args.colormap
cnres.cnLinesOn       = False
cnres.cnLineLabelsOn  = False

# Labelbar resource
cnres.lbOrientation   = "horizontal"

# Scalar field resources
cnres.sfXArray        = lon
cnres.sfYArray        = lat
cnres.sfMissingValueV = missing_value

# Map resources
cnres.mpFillOn               = True
cnres.mpFillDrawOrder        = "PostDraw"
cnres.mpLandFillColor        = ("Transparent" if args.land_transparent else "Gray") 
cnres.mpOceanFillColor       = "Transparent"
cnres.mpInlandWaterFillColor = "Transparent"
cnres.mpCenterLonF           = 200.0


if args.auto_clevs == False:
    cnres.cnLevelSelectionMode   = "ManualLevels"
    cnres.cnMinLevelValF         = args.cmin
    cnres.cnMaxLevelValF         = args.cmax
    cnres.cnLevelSpacingF        = (args.cmax - args.cmin) / args.clevs

cnres.lbOrientation = "horizontal"
cnres.lbTitleString = args.clabel
cnres.lbTitlePosition = "Bottom"
#cnres.lbTitleAngleF = 90.0

cnres.tiMainFontHeightF = 0.01
cnres.tiMainString         = args.title

plot = Ngl.contour_map(wks, data, cnres)

Ngl.end()




