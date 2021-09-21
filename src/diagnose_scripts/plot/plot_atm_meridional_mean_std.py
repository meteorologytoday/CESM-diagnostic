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
parser.add_argument('--lev-file', type=str, default="")
parser.add_argument('--lev-varname', type=str, default="lev")
parser.add_argument('--output-dir')
parser.add_argument('--casename')

parser.add_argument('--varname-mean')
parser.add_argument('--varname-std')
parser.add_argument('--title', default="")
parser.add_argument('--subtitles', default="")
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
parser.add_argument('--idx-x', type=int, default=-1)
parser.add_argument('--extra-filename', default="")
parser.add_argument('--land-transparent', action="store_true", default=False)
parser.add_argument('--central-longitude', type=float, default=180.0)
parser.add_argument('--figsize', type=str, default="20,8")


args = parser.parse_args()

figsize   = tuple(map(float, args.figsize.split(',')))
subtitles = tuple(map(str, args.subtitles.split(',')))


if args.lev_file == "":
    args.lev_file = args.data_file

f = Dataset(args.data_file, "r")
g = Dataset(args.domain_file, "r")
h = Dataset(args.lev_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat
lev = h.variables[args.lev_varname][:]          #-- read level

g.close()
h.close()

args.scale = eval(args.scale)

var_mean = f.variables[args.varname_mean]
var_std  = f.variables[args.varname_std]

if args.idx_x == -1:
    data_mean = var_mean[:, :, :]
    data_std  = var_std[:, :, :]
else:
    data_mean = var_mean[:, :, :, args.idx_x]
    data_std  = var_std[:, :, :, args.idx_x]


if data_mean.shape[0] != data_std.shape[0]:
    raise Exception("Data lengths of mean and std in time must match.")

data_N, Nz, Ny = data_mean.shape


if args.tick_levs_mean == -1:
    args.tick_levs_mean = args.clevs

if args.tick_levs_std == -1:
    args.tick_levs_std = args.clevs




"""

DOM = np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])


for s in range(4):
    N = 0
    for m in range(s*3, (s+1)*3):
        N += DOM[m]
        _data_mean[s, :, :] +=  data_mean[m, :, :] * DOM[m]
        _data_var[s, :, :]  +=  ( data_mean[m, :, :]**2.0 + data_var[m, :, :] ) * DOM[m]

    _data_mean[s, :, :] /= N
    _data_var[s, :, :] = _data_var[s, :, :] / N - _data_mean[s, :, :] ** 2.0
    _data_std[s, :, :] = np.sqrt(_data_var[s, :, :])

_data_mean -= args.offset
_data_mean /= args.scale
_data_std  /= args.scale
"""

f.close()


clevels_mean = np.linspace(args.cmin_mean, args.cmax_mean, args.clevs+1)
clevels_std = np.linspace(0, args.cmax_std, args.clevs+1)
cmap_mean = cm.get_cmap(args.colormap_mean)
cmap_std  = cm.get_cmap(args.colormap_std)

tick_levels_mean = np.linspace(args.cmin_mean, args.cmax_mean, args.tick_levs_mean+1)
tick_levels_std = np.linspace(0, args.cmax_std, args.tick_levs_std+1)


fig, ax = plt.subplots(nrows=2, ncols=data_N, figsize=figsize)

fig.suptitle(args.title)

for s in range(data_N):
 
  
    ax0 = ax[0, s]
    ax1 = ax[1, s]

    _mean = data_mean[s, :, :]
    _std  = data_std[s, :, :]

    mappable_mean = ax0.contourf(lat, lev, _mean, clevels_mean, cmap=cmap_mean, extend="both")
    mappable_std  = ax1.contourf(lat, lev, _std,  clevels_std,  cmap=cmap_std,  extend="max")


    ax0.set_title(subtitles[s])
    ax1.set_xlabel("Latitude [deg]")
    ax0.set_xlim([-90, 90])
    ax1.set_xlim([-90, 90])
    ax0.set_xticks([-90, -60, -30, 0, 30, 60, 90])
    ax1.set_xticks([-90, -60, -30, 0, 30, 60, 90])

    for a in ax[:, s]:
        a.invert_yaxis()
        #a.set_global()
        #a.set_aspect('auto')
 
cb_mean = fig.colorbar(mappable_mean, ax=ax[0, :], orientation="vertical", ticks=tick_levels_mean)
cb_std  = fig.colorbar(mappable_std, ax=ax[1, :], orientation="vertical", ticks=tick_levels_std)

cb_mean.ax.set_ylabel(args.clabel_mean, rotation=90)
cb_std.ax.set_ylabel(args.clabel_std, rotation=90)

filename = "%s/%s_atm_meridional_mean_std_%s.png" % (args.output_dir, args.casename, args.extra_filename)
fig.savefig(filename, dpi=200)
print("Output %s" % (filename,))
