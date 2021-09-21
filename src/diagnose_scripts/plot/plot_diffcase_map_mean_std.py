import cartopy.crs as ccrs
import matplotlib as mplt
mplt.use('Agg')

import matplotlib.pyplot as plt
from matplotlib import cm

from netCDF4 import Dataset

import sys, argparse
import numpy as np


cb_fraction = 45
default_linewidth = 2.0
default_ticksize = 10.0


small_fontsize = 15.0
default_fontsize = 20.0
large_fontsize = 40.0
mplt.rcParams.update({
    'font.size'         : default_fontsize,
    'lines.linewidth'   : default_linewidth,
    'axes.linewidth'    : default_linewidth,
    'axes.labelsize'    : large_fontsize,
    'xtick.major.size'  : 5,
    'xtick.major.width' : default_linewidth,
    'ytick.major.size'  : 5,
    'ytick.major.width' : default_linewidth,
    'mathtext.fontset'  : 'stixsans',
    'xtick.major.pad'   : 5,
    'ytick.major.pad'   : 5,
    'xtick.labelsize'   : small_fontsize,
    'ytick.labelsize'   : small_fontsize,
})


def ext(data):
    s = data.shape
    ndata = np.zeros((s[0], s[1]+1))
    ndata[:, 0:-1] = data
    ndata[:, -1] = data[:, 0]
    return ndata
 

def ext_axis(lon):
    return np.append(lon, 360) 
 
parser = argparse.ArgumentParser()
parser.add_argument('--data-dir')
parser.add_argument('--ref-data-dir')
parser.add_argument('--data-file')

parser.add_argument('--casenames')
parser.add_argument('--ref-casenames')
parser.add_argument('--legends')

parser.add_argument('--domain-file')
parser.add_argument('--lev-file', type=str, default="")
parser.add_argument('--lev-varname', type=str, default="lev")
parser.add_argument('--output-dir')

parser.add_argument('--varname-mean')
parser.add_argument('--varname-std')
parser.add_argument('--title', default="")
parser.add_argument('--subtitles', default="")
parser.add_argument('--colormap-mean-diff', default="bwr")
parser.add_argument('--colormap-std-diff', default="bwr")
parser.add_argument('--auto-clevs', action="store_true", default=False)
parser.add_argument('--cmax-mean-diff', type=float)
parser.add_argument('--cmax-std-diff', type=float)
parser.add_argument('--clevs-mean-diff', type=int)
parser.add_argument('--clevs-std-diff', type=int)
parser.add_argument('--tick-levs-mean-diff', type=int, default=-1)
parser.add_argument('--tick-levs-std-diff', type=int, default=-1)
parser.add_argument('--clabel-mean-diff', default="")
parser.add_argument('--clabel-std-diff', default="")
parser.add_argument('--offset', type=float, default=0.0)
parser.add_argument('--scale', default="1.0")
parser.add_argument('--idx-t', type=int, default=-1)
parser.add_argument('--idx-z', type=int, default=-1)
parser.add_argument('--extra-filename', default="")
parser.add_argument('--land-transparent', action="store_true", default=False)
parser.add_argument('--central-longitude', type=float, default=180.0)
parser.add_argument('--figsize', type=str, default="20,20")


args = parser.parse_args()


print(args)

casenames = args.casenames.split(',')
ref_casenames = args.ref_casenames.split(',')
legends = args.legends.split(',')

figsize   = tuple(map(float, args.figsize.split(',')))
subtitles = tuple(map(str, args.subtitles.split(',')))

idxes = [slice(None), slice(None), slice(None)] if args.idx_z == -1 else [slice(None), args.idx_z, slice(None), slice(None)]

N_cases = len(casenames)

if args.lev_file == "":
    args.lev_file = args.data_file

g = Dataset(args.domain_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat

g.close()

scale = eval(args.scale)

datas1 = []
datas2 = []

for i in range(N_cases):

    print("Loading case: %s" % casenames[i])    
    print("        case: %s" % ref_casenames[i])    
    f1 = Dataset("%s/%s/%s" % (args.data_dir, casenames[i], args.data_file), "r")
    f2 = Dataset("%s/%s/%s" % (args.ref_data_dir, ref_casenames[i], args.data_file), "r")
    
    datas1.append([f1.variables[args.varname_mean][idxes] / scale , f1.variables[args.varname_std][idxes] / scale])
    datas2.append([f2.variables[args.varname_mean][idxes] / scale, f2.variables[args.varname_std][idxes] / scale])

    f1.close()
    f2.close()


data_N, Ny, Nx = datas1[0][0].shape

clevels_mean_diff = np.linspace(-args.cmax_mean_diff, args.cmax_mean_diff, args.clevs_mean_diff+1 )
clevels_std_diff  = np.linspace(-args.cmax_std_diff,  args.cmax_std_diff,  args.clevs_std_diff+1  )

cmap_mean_diff = cm.get_cmap(args.colormap_mean_diff)
cmap_std_diff  = cm.get_cmap(args.colormap_std_diff)

tick_levels_mean_diff = np.linspace(-args.cmax_mean_diff,  args.cmax_mean_diff, args.tick_levs_mean_diff+1)
tick_levels_std_diff  = np.linspace(-args.cmax_std_diff,   args.cmax_std_diff,  args.tick_levs_std_diff+1)

# I think this is a bug in cartopy that projection are not consistent
proj1 = ccrs.PlateCarree(central_longitude=args.central_longitude)
proj2 = ccrs.PlateCarree(central_longitude=0.0)


### Plot Mean ###
fig, axes = plt.subplots(nrows=N_cases, ncols=data_N, figsize=figsize, subplot_kw={'projection': proj1, 'aspect': 1.5}, squeeze=False)
fig.suptitle("[MEAN] %s " % args.title)

for s in range(data_N):
 
    ax = axes[:, s] 

    ax[0].set_title(subtitles[s], size=40, y=1.1)
    
    for k in range(N_cases):

        mean1 = datas1[k][0][s, :, :]
        mean2 = datas2[k][0][s, :, :]
        mean12 = mean1 - mean2

        a = ax[k]

        mappable_mean_diff = a.contourf(lon, lat, mean12, clevels_mean_diff, cmap=cmap_mean_diff, extend="both", transform=proj2)
        a.set_xlim([-90, 90])
        a.set_xticks(np.linspace(-180, 180, 7))
        a.set_xticklabels(["%d" % d for d in np.linspace(0, 360, 7)])

        a.set_yticks(np.linspace(-90,  90, 7))
        a.set_yticklabels(["%d" % d for d in np.linspace(-90,  90, 7)])

        a.set_global()
        a.coastlines()
    
for k in range(N_cases):
    axes[k, 0].set_ylabel(legends[k], size=25)
     
cb_mean_diff  = fig.colorbar(mappable_mean_diff, ax=axes[:, :], orientation="vertical", ticks=tick_levels_mean_diff, aspect=cb_fraction)

cb_mean_diff.ax.set_ylabel(args.clabel_mean_diff, rotation=90, labelpad=40)
cb_mean_diff.ax.tick_params(labelsize=30)

filename = "%s/diffcase_map_mean_std_[MEAN]%s.png" % (args.output_dir, args.extra_filename)
fig.savefig(filename, dpi=300, transparent=True)

plt.close(fig)

### Plot Standard Deviation ###
fig, axes = plt.subplots(nrows=N_cases, ncols=data_N, figsize=figsize, subplot_kw={'projection': proj1, 'aspect': 1.5}, squeeze=False)
fig.suptitle("[STD] %s" % args.title)

for s in range(data_N):
 
    ax = axes[:, s] 

    ax[0].set_title(subtitles[s])

    for k in range(N_cases):

        a = ax[k]
        std1  = datas1[k][1][s, :, :]
        std2  = datas2[k][1][s, :, :]
        std12  = std1  - std2
        mappable_std_diff  = a.contourf(lon, lat, std12,  clevels_std_diff,  cmap=cmap_std_diff, extend="both", transform=proj2)

        a.set_xlim([-90, 90])
        a.set_xticks(np.linspace(-180, 180, 7))
        a.set_xticklabels(["%d" % d for d in np.linspace(0, 360, 7)])

        a.set_yticks(np.linspace(-90,  90, 7))
        a.set_yticklabels(["%d" % d for d in np.linspace(-90,  90, 7)])

        a.set_global()
        a.coastlines()
    
for k in range(N_cases):
    axes[k, 0].set_ylabel(legends[k], size=25)
     
cb_std_diff   = fig.colorbar(mappable_std_diff,  ax=axes[:, :], orientation="vertical", ticks=tick_levels_std_diff, aspect=cb_fraction)
cb_std_diff.ax.set_ylabel(args.clabel_std_diff, rotation=90, labelpad=40)
cb_std_diff.ax.tick_params(labelsize=30)

filename = "%s/diffcase_map_mean_std_[STD]%s.png" % (args.output_dir, args.extra_filename)
fig.savefig(filename, dpi=300, transparent=True)

print("Output %s" % (filename,))
