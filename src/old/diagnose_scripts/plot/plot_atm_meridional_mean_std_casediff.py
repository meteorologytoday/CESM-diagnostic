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
parser.add_argument('--data-file-1')
parser.add_argument('--data-file-2')
parser.add_argument('--domain-file')
parser.add_argument('--lev-file', type=str, default="")
parser.add_argument('--lev-varname', type=str, default="lev")
parser.add_argument('--output-dir')

parser.add_argument('--varname-mean')
parser.add_argument('--varname-std')
parser.add_argument('--title', default="")
parser.add_argument('--subtitles', default="")
parser.add_argument('--colormap-mean', default="bwr")
parser.add_argument('--colormap-std', default="hot_r")
parser.add_argument('--colormap-mean-diff', default="bwr")
parser.add_argument('--colormap-std-diff', default="bwr")
parser.add_argument('--auto-clevs', action="store_true", default=False)
parser.add_argument('--cmin-mean', type=float)
parser.add_argument('--cmax-mean', type=float)
parser.add_argument('--cmax-std', type=float)
parser.add_argument('--cmax-mean-diff', type=float)
parser.add_argument('--cmax-std-diff', type=float)
#parser.add_argument('--clevs', type=int, default=10)
parser.add_argument('--clevs-mean', type=int)
parser.add_argument('--clevs-std', type=int)
parser.add_argument('--clevs-mean-diff', type=int)
parser.add_argument('--clevs-std-diff', type=int)
parser.add_argument('--tick-levs-mean', type=int, default=-1)
parser.add_argument('--tick-levs-std', type=int, default=-1)
parser.add_argument('--tick-levs-mean-diff', type=int, default=-1)
parser.add_argument('--tick-levs-std-diff', type=int, default=-1)
parser.add_argument('--clabel-mean', default="")
parser.add_argument('--clabel-std', default="")
parser.add_argument('--clabel-mean-diff', default="")
parser.add_argument('--clabel-std-diff', default="")
parser.add_argument('--offset', type=float, default=0.0)
parser.add_argument('--scale', default="1.0")
parser.add_argument('--idx-t', type=int, default=-1)
parser.add_argument('--idx-x', type=int, default=-1)
parser.add_argument('--extra-filename', default="")
parser.add_argument('--land-transparent', action="store_true", default=False)
parser.add_argument('--central-longitude', type=float, default=180.0)
parser.add_argument('--figsize', type=str, default="20,20")


args = parser.parse_args()

figsize   = tuple(map(float, args.figsize.split(',')))
subtitles = tuple(map(str, args.subtitles.split(',')))


if args.lev_file == "":
    args.lev_file = args.data_file

f1 = Dataset(args.data_file_1, "r")
f2 = Dataset(args.data_file_2, "r")
g = Dataset(args.domain_file, "r")
h = Dataset(args.lev_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat
lev = h.variables[args.lev_varname][:]          #-- read level

g.close()
h.close()

args.scale = eval(args.scale)

var1_mean = f1.variables[args.varname_mean]
var1_std  = f1.variables[args.varname_std]

var2_mean = f2.variables[args.varname_mean]
var2_std  = f2.variables[args.varname_std]


if args.idx_x == -1:
    var1_mean = var1_mean[:, :, :]
    var1_std  = var1_std[:, :, :]
    var2_mean = var2_mean[:, :, :]
    var2_std  = var2_std[:, :, :]

else:
    var1_mean = var1_mean[:, :, :, args.idx_x]
    var1_std  = var1_std[:, :, :, args.idx_x]
    var2_mean = var2_mean[:, :, :, args.idx_x]
    var2_std  = var2_std[:, :, :, args.idx_x]


f1.close()
f2.close()

if var1_mean.shape[0] != var1_std.shape[0] or var2_mean.shape[0] != var2_std.shape[0] or var1_mean.shape[0] != var2_mean.shape[0]:
    raise Exception("Data lengths of mean and std in time must match.")

data_N, Nz, Ny = var1_mean.shape

if args.tick_levs_mean == -1:
    args.tick_levs_mean = args.clevs

if args.tick_levs_std == -1:
    args.tick_levs_std = args.clevs


clevels_mean      = np.linspace(args.cmin_mean,       args.cmax_mean,      args.clevs_mean+1      )
clevels_std       = np.linspace(0,                    args.cmax_std,       args.clevs_std+1       )
clevels_mean_diff = np.linspace(-args.cmax_mean_diff, args.cmax_mean_diff, args.clevs_mean_diff+1 )
clevels_std_diff  = np.linspace(-args.cmax_std_diff,  args.cmax_std_diff,  args.clevs_std_diff+1  )

cmap_mean      = cm.get_cmap(args.colormap_mean)
cmap_std       = cm.get_cmap(args.colormap_std)
cmap_mean_diff = cm.get_cmap(args.colormap_mean_diff)
cmap_std_diff  = cm.get_cmap(args.colormap_std_diff)


tick_levels_mean      = np.linspace(args.cmin_mean,   args.cmax_mean,      args.tick_levs_mean+1)
tick_levels_std       = np.linspace(0,                args.cmax_std,       args.tick_levs_std+1)
tick_levels_mean_diff = np.linspace(-args.cmax_mean_diff,  args.cmax_mean_diff, args.tick_levs_mean_diff+1)
tick_levels_std_diff  = np.linspace(-args.cmax_std_diff,   args.cmax_std_diff,  args.tick_levs_std_diff+1)



fig, axes = plt.subplots(nrows=6, ncols=data_N, figsize=figsize)

fig.suptitle(args.title)

for s in range(data_N):
 
    ax = axes[:, s] 

    mean1 = var1_mean[s, :, :]
    std1  = var1_std[s, :, :]
    mean2 = var2_mean[s, :, :]
    std2  = var2_std[s, :, :]

    mean12 = mean1 - mean2
    std12  = std1  - std2

    mappable_mean      = ax[0].contourf(lat, lev, mean1,  clevels_mean,      cmap=cmap_mean, extend="both")
    _                  = ax[1].contourf(lat, lev, mean2,  clevels_mean,      cmap=cmap_mean, extend="both")
    mappable_mean_diff = ax[2].contourf(lat, lev, mean12, clevels_mean_diff, cmap=cmap_mean_diff, extend="both")
    
    mappable_std       = ax[3].contourf(lat, lev, std1,   clevels_std,       cmap=cmap_std,  extend="max")
    _                  = ax[4].contourf(lat, lev, std2,   clevels_std,       cmap=cmap_std,  extend="max")
    mappable_std_diff  = ax[5].contourf(lat, lev, std12,  clevels_std_diff,  cmap=cmap_std_diff, extend="both")


    ax[0].set_title(subtitles[s])

    ax[5].set_xlabel("Latitude [deg]")
    
    for i in range(5):
        ax[i].set_xlim([-90, 90])
        ax[i].set_xticks([-90, -60, -30, 0, 30, 60, 90])

    for a in ax:
        a.set_yticks([100, 200, 500, 850, 1000])
        a.invert_yaxis()
        #a.set_global()
        #a.set_aspect('auto')
 
cb_mean1      = fig.colorbar(mappable_mean,      ax=axes[0, :], orientation="vertical", ticks=tick_levels_mean)
cb_mean2      = fig.colorbar(mappable_mean,      ax=axes[1, :], orientation="vertical", ticks=tick_levels_mean)
cb_mean_diff  = fig.colorbar(mappable_mean_diff, ax=axes[2, :], orientation="vertical", ticks=tick_levels_mean_diff)
cb_std1       = fig.colorbar(mappable_std,       ax=axes[3, :], orientation="vertical", ticks=tick_levels_std)
cb_std2       = fig.colorbar(mappable_std,       ax=axes[4, :], orientation="vertical", ticks=tick_levels_std)
cb_std_diff   = fig.colorbar(mappable_std_diff,  ax=axes[5, :], orientation="vertical", ticks=tick_levels_std_diff)

cb_mean1.ax.set_ylabel(args.clabel_mean, rotation=90)
cb_mean2.ax.set_ylabel(args.clabel_mean, rotation=90)
cb_mean_diff.ax.set_ylabel(args.clabel_mean_diff, rotation=90)

cb_std1.ax.set_ylabel(args.clabel_std, rotation=90)
cb_std2.ax.set_ylabel(args.clabel_std, rotation=90)
cb_std_diff.ax.set_ylabel(args.clabel_std_diff, rotation=90)


filename = "%s/atm_meridional_mean_std_%s.png" % (args.output_dir, args.extra_filename)
fig.savefig(filename, dpi=200)
print("Output %s" % (filename,))
