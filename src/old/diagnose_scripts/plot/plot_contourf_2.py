import cartopy.crs as ccrs
import matplotlib as mplt
mplt.use('Agg')

import matplotlib.pyplot as plt
from matplotlib import cm



from netCDF4 import Dataset

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
parser.add_argument('--colormap-mean', default="bwr")
parser.add_argument('--colormap-std', default="hot_r")
parser.add_argument('--auto-clevs', action="store_true", default=False)
parser.add_argument('--cmin-mean', type=float)
parser.add_argument('--cmax-mean', type=float)
parser.add_argument('--cmax-std', type=float)
parser.add_argument('--clevs', type=int)
parser.add_argument('--tick-levs-mean', type=int, default=-1)
parser.add_argument('--tick-levs-std', type=int, default=-1)
parser.add_argument('--clabel-mean', default="")
parser.add_argument('--clabel-std', default="")
parser.add_argument('--offset', type=float, default=0.0)
parser.add_argument('--scale', default="1.0")
parser.add_argument('--idx-t', type=int, default=-1)
parser.add_argument('--idx-z', type=int, default=-1)
parser.add_argument('--extra-filename', default="")
parser.add_argument('--land-transparent', action="store_true", default=False)
parser.add_argument('--central-longitude', type=float, default=180.0)


args = parser.parse_args()

f = Dataset(args.data_file, "r")
g = Dataset(args.domain_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat

args.scale = eval(args.scale)

var_mean = f.variables[args.varname_mean]

if args.idx_z == -1:
    data_mean = var_mean[:, :, :]
else:
    data_mean = var_mean[:, args.idx_z, :, :]

if data_mean.shape[0] != 12 or data_var.shape[0] != 12:
    raise Exception("Data length in time is not 12.")


if args.tick_levs_mean == -1:
    args.tick_levs_mean = args.clevs

if args.tick_levs_std == -1:
    args.tick_levs_std = args.clevs


_, Ny, Nx = data_mean.shape

DOM = np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])


data_mean -= args.offset
data_mean /= args.scale

f.close()


# Extend data to avoid a white stripe on the 0-deg lon
lon = ext_axis(lon)

clevels_mean = np.linspace(args.cmin_mean, args.cmax_mean, args.clevs+1)
cmap_mean = cm.get_cmap(args.colormap_mean)

tick_levels_mean = np.linspace(args.cmin_mean, args.cmax_mean, args.tick_levs_mean+1)

# I think this is a bug in cartopy that projection are not consistent
proj1 = ccrs.PlateCarree(central_longitude=args.central_longitude)
proj2 = ccrs.PlateCarree(central_longitude=0.0)


fig, ax = plt.subplots(nrows=3, ncols=2, subplot_kw={'projection': proj1, 'aspect': 1.5}, figsize=(20,8))
fig.suptitle(args.title)

for a in ax.flatten():
    a.coastlines()
    a.set_global()
    #a.set_aspect('auto')

    ax1 = ax[1, s]

    _mean = ext(_data_mean[s, :, :])
    _std  = ext(_data_std[s, :, :])

    mappable_mean = ax0.contourf(lon, lat, _mean, clevels_mean, cmap=cmap_mean, extend="both", transform=proj2)
    mappable_std  = ax1.contourf(lon, lat, _std, clevels_std, cmap=cmap_std, extend="max", transform=proj2)


ax0.set_title(["01-03", "04-06", "07-09", "10-12"][s])

cb_mean = fig.colorbar(mappable_mean, ax=ax[0, :], orientation="vertical", ticks=tick_levels_mean)
cb_std  = fig.colorbar(mappable_std, ax=ax[1, :], orientation="vertical", ticks=tick_levels_std)

cb_mean.ax.set_ylabel(args.clabel_mean, rotation=90)
cb_std.ax.set_ylabel(args.clabel_std, rotation=90)

filename = "%s/%s_4seasons_contourf_%s.png" % (args.output_dir, args.casename, args.extra_filename)
fig.savefig(filename, dpi=200)
print("Output %s" % (filename,))
