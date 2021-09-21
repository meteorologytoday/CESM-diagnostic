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
parser.add_argument('--idx-x', type=int, default=-1)
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

idxes = [slice(None), slice(None), slice(None)] if args.idx_x == -1 else [slice(None), slice(None), slice(None), args.idx_x]

N_cases = len(casenames)

if args.lev_file == "":
    args.lev_file = args.data_file

g = Dataset(args.domain_file, "r")
h = Dataset(args.lev_file, "r")

lon = g.variables["xc"][1, :]                   #-- read clon
lat = g.variables["yc"][:, 1]                   #-- read clat
lev = h.variables[args.lev_varname][:]          #-- read level

g.close()
h.close()

args.scale = eval(args.scale)

datas1 = []
datas2 = []

for i in range(N_cases):
    
    f1 = Dataset("%s/%s/%s" % (args.data_dir, casenames[i], args.data_file), "r")
    f2 = Dataset("%s/%s/%s" % (args.ref_data_dir, ref_casenames[i], args.data_file), "r")
    
    datas1.append([f1.variables[args.varname_mean][idxes] / args.scale, f1.variables[args.varname_std][idxes] / args.scale])
    datas2.append([f2.variables[args.varname_mean][idxes] / args.scale, f2.variables[args.varname_std][idxes] / args.scale])

    f1.close()
    f2.close()


data_N, Nz, Ny = datas1[0][0].shape

"""
if args.tick_levs_mean == -1:
    args.tick_levs_mean = args.clevs

if args.tick_levs_std == -1:
    args.tick_levs_std = args.clevs
"""

clevels_mean_diff = np.linspace(-args.cmax_mean_diff, args.cmax_mean_diff, args.clevs_mean_diff+1 )
clevels_std_diff  = np.linspace(-args.cmax_std_diff,  args.cmax_std_diff,  args.clevs_std_diff+1  )

cmap_mean_diff = cm.get_cmap(args.colormap_mean_diff)
cmap_std_diff  = cm.get_cmap(args.colormap_std_diff)

tick_levels_mean_diff = np.linspace(-args.cmax_mean_diff,  args.cmax_mean_diff, args.tick_levs_mean_diff+1)
tick_levels_std_diff  = np.linspace(-args.cmax_std_diff,   args.cmax_std_diff,  args.tick_levs_std_diff+1)

fig, axes = plt.subplots(nrows=N_cases * 2, ncols=data_N, figsize=figsize)
fig.suptitle(args.title)

for s in range(data_N):
 
    ax = axes[:, s] 

    ax[0].set_title(subtitles[s])
    ax[-1].set_xlabel("Latitude [deg]")

    for k in range(N_cases):

        mean1 = datas1[k][0][s, :, :]
        std1  = datas1[k][1][s, :, :]
        mean2 = datas2[k][0][s, :, :]
        std2  = datas2[k][1][s, :, :]

        mean12 = mean1 - mean2
        std12  = std1  - std2

        mappable_mean_diff = ax[k].contourf(lat, lev, mean12, clevels_mean_diff, cmap=cmap_mean_diff, extend="both")
        mappable_std_diff  = ax[ N_cases + k ].contourf(lat, lev, std12,  clevels_std_diff,  cmap=cmap_std_diff, extend="both")

        
        for a in [ax[k], ax[N_cases+k]]:        
            a.set_xlim([-90, 90])
            a.set_xticks([-90, -60, -30, 0, 30, 60, 90])

            a.set_yticks([100, 200, 500, 850, 1000])
            a.invert_yaxis()

        
        #a.set_global()
        #a.set_aspect('auto')
    
for k in range(N_cases):
    axes[k, 0].set_ylabel(legends[k])
    axes[N_cases+k, 0].set_ylabel(legends[k])
     
cb_mean_diff  = fig.colorbar(mappable_mean_diff, ax=axes[0:N_cases, :], orientation="vertical", ticks=tick_levels_mean_diff)
cb_std_diff   = fig.colorbar(mappable_std_diff,  ax=axes[N_cases:, :], orientation="vertical", ticks=tick_levels_std_diff)

cb_mean_diff.ax.set_ylabel(args.clabel_mean_diff, rotation=90)
cb_std_diff.ax.set_ylabel(args.clabel_std_diff, rotation=90)


filename = "%s/diffcase_atm_meridional_mean_std_%s.png" % (args.output_dir, args.extra_filename)
fig.savefig(filename, dpi=200)
print("Output %s" % (filename,))
