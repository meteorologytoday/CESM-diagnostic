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
parser.add_argument('--output-dir')

parser.add_argument('--varname-mean')
parser.add_argument('--title', default="")
parser.add_argument('--subtitles', default="")
parser.add_argument('--colormap-mean-diff', default="bwr")
parser.add_argument('--auto-clevs', action="store_true", default=False)
parser.add_argument('--cmax-mean-diff', type=float)
parser.add_argument('--clevs-mean-diff', type=int)
parser.add_argument('--tick-levs-mean-diff', type=int, default=-1)
parser.add_argument('--clabel-mean-diff', default="")
parser.add_argument('--offset', type=float, default=0.0)
parser.add_argument('--scale', default="1.0")
parser.add_argument('--idx-t', type=int, default=-1)
parser.add_argument('--idx-z', type=int, default=-1)
parser.add_argument('--extra-filename', default="")
parser.add_argument('--land-transparent', action="store_true", default=False)
parser.add_argument('--central-longitude', type=float, default=180.0)
parser.add_argument('--figsize', type=str, default="20,20")

parser.add_argument('--nrows', type=int, default=-1)
parser.add_argument('--ncols', type=int, default=-1)

args = parser.parse_args()


print(args)


    
    


casenames = args.casenames.split(',')
ref_casenames = args.ref_casenames.split(',')
legends = args.legends.split(',')

figsize   = tuple(map(float, args.figsize.split(',')))
subtitles = tuple(map(str, args.subtitles.split(',')))

idxes = [slice(None), slice(None), slice(None)] if args.idx_z == -1 else [slice(None), args.idx_z, slice(None), slice(None)]

N_cases = len(casenames)

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
    
    datas1.append([f1.variables[args.varname_mean][idxes] / scale])
    datas2.append([f2.variables[args.varname_mean][idxes] / scale])

    f1.close()
    f2.close()


data_N, Ny, Nx = datas1[0][0].shape

if args.nrows == -1 and args.ncols == -1:

    args.nrows = N_cases
    args.ncols = 1

elif args.nrows == -1 != args.ncols == -1:

    raise Exception("nrows and ncols must be specified at the same time")


clevels_mean_diff = np.linspace(-args.cmax_mean_diff, args.cmax_mean_diff, args.clevs_mean_diff+1 )

cmap_mean_diff = cm.get_cmap(args.colormap_mean_diff)

tick_levels_mean_diff = np.linspace(-args.cmax_mean_diff,  args.cmax_mean_diff, args.tick_levs_mean_diff+1)

# I think this is a bug in cartopy that projection are not consistent
proj1 = ccrs.PlateCarree(central_longitude=args.central_longitude)
proj2 = ccrs.PlateCarree(central_longitude=0.0)


### Plot Mean ###
fig, axes = plt.subplots(nrows=args.nrows, ncols=args.ncols, figsize=figsize, subplot_kw={'projection': proj1, 'aspect': 1.5}, squeeze=False)
fig.suptitle(args.title)

for (k, a) in enumerate(axes.flatten(order='F')):

    print(len(datas1[k]))
    mean1 = datas1[k][0][0, :, :]
    mean2 = datas2[k][0][0, :, :]
    mean12 = mean1 - mean2

    #print(lon.shape)
   # print(mean12.shape)

    mappable_mean_diff = a.contourf(lon, lat, mean12, clevels_mean_diff, cmap=cmap_mean_diff, extend="both", transform=proj2)
    a.set_xlim([-90, 90])
    a.set_xticks(np.linspace(-180, 180, 7))
    a.set_xticklabels(["%d" % d for d in np.linspace(0, 360, 7)])

    a.set_yticks(np.linspace(-90,  90, 7))
    a.set_yticklabels(["%d" % d for d in np.linspace(-90,  90, 7)])

    a.set_global()
    a.coastlines()

    a.set_title(legends[k], size=35, y=1.02)
     
cb_mean_diff  = fig.colorbar(mappable_mean_diff, ax=axes[:, :], orientation="vertical", ticks=tick_levels_mean_diff, aspect=cb_fraction)

cb_mean_diff.ax.set_ylabel(args.clabel_mean_diff, rotation=90, labelpad=40)
cb_mean_diff.ax.tick_params(labelsize=30)

filename = "%s/diffcase_map_contourf%s.png" % (args.output_dir, args.extra_filename)
fig.savefig(filename, dpi=200, transparent=True)

plt.close(fig)

