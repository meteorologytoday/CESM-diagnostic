import matplotlib as mplt
mplt.use('Agg')

from matplotlib import rc

default_linewidth = 2.0;
default_ticksize = 10.0;

mplt.rcParams['lines.linewidth'] =   default_linewidth;
mplt.rcParams['axes.linewidth'] =    default_linewidth;
mplt.rcParams['xtick.major.size'] =  default_ticksize;
mplt.rcParams['xtick.major.width'] = default_linewidth;
mplt.rcParams['ytick.major.size'] =  default_ticksize;
mplt.rcParams['ytick.major.width'] = default_linewidth;

#rc('font', **{'family':'sans-serif', 'serif': 'Bitstream Vera Serif', 'sans-serif': 'MS Reference Sans Serif', 'size': 20.0});
rc('font', **{'size': 20.0});
rc('axes', **{'labelsize': 20.0});
rc('mathtext', **{'fontset':'stixsans'});
rc(('xtick.major','ytick.major'), pad=20)

#import matplotlib.font_manager as fm;
#print("%s: %d"%(fm.FontProperties().get_name(),fm.FontProperties().get_weight()));

import matplotlib.pyplot as plt

import sys, argparse
from netCDF4 import Dataset
import numpy as np
from pprint import pprint

parser = argparse.ArgumentParser()
parser.add_argument('--input-dir')
parser.add_argument('--output-dir')
parser.add_argument('--casenames')
parser.add_argument('--legends')
parser.add_argument('--data-file')
parser.add_argument('--domain-file')
parser.add_argument('--extra-title', default="")
parser.add_argument('--extra-filename', default="")
parser.add_argument('--colors')
parser.add_argument('--linestyles', type=str)

args = parser.parse_args()

pprint(args)

casenames  = args.casenames.split(",")
legends    = args.legends.split(",")
colors     = args.colors.split(",")
linestyles = args.linestyles.split(",")

print("Going to compare these models:")
pprint(casenames)

mean_datas = []

datas = {}
for i in range(len(casenames)):
    
    print("Loading casename: %s" % (casenames[i],))

    try:

        f = Dataset("%s/%s/%s" % (args.input_dir, casenames[i], args.data_file), "r")

    except Exception as e:
   
        print(str(e)) 
        print("Error happens when doing casename %s. Going to ignore this one..." % casenames[i])

        continue
    

    _data = {}
    
    for varname in ["swflx", "nswflx", "TFLUX_DIV_implied", "qflx", "TSAS_clim", "TFLUX_bot"]:
        v = f.variables[varname][:]
        v[np.isnan(v)] = 0.0
        #np.nan_to_num(v, nan=0.0)
        _data[varname] = np.nanmean(v, axis=1)
   
    datas[casenames[i]] = _data
     
    f.close()

with Dataset(args.domain_file, "r") as f:
    lat = f.variables["yc"][:, 1]


fig, ax = plt.subplots(3, 1, figsize=(16, 20), sharex=True)

rhocp = 1026.0 * 3996.0

for i, casename in enumerate(casenames):

    if (casename in datas) == False:
        continue
 
    _data = datas[casename]
    ax[0].plot(lat, _data["TFLUX_DIV_implied"] * rhocp, linewidth=2, label=legends[i], color=colors[i], linestyle=linestyles[i])
    ax[1].plot(lat, _data["qflx"],                      linewidth=2, label=legends[i], color=colors[i], linestyle=linestyles[i])
    ax[2].plot(lat, _data["TSAS_clim"] * rhocp,         linewidth=2, label=legends[i], color=colors[i], linestyle=linestyles[i])

    ax[0].set_ylabel("Horizontal advection [$ \mathrm{W} \, \mathrm{m}^{-2} $]")
    ax[1].set_ylabel("Q-flux [$ \mathrm{W} \, \mathrm{m}^{-2} $]")
    ax[2].set_ylabel("Deep ocean restoration [$ \mathrm{W} \, \mathrm{m}^{-2} $]")

for a in ax:
    a.set_ylim([-40,60])
    a.set_yticks([-40, -20, 0, 20, 40 ,60])
    a.grid(True)

ax[0].legend(loc='center left', bbox_to_anchor=(1, 0.5), frameon=False)
fig.subplots_adjust(right=0.7, bottom=0.2)

fig.suptitle("%sOcean energy analysis" % args.extra_title)

ax[2].set_xlim([-90, 90])
ax[2].set_xlabel("Latitude [deg]")
ax[2].set_xticks([-90, -60, -30, 0, 30, 60, 90])

ax[0].invert_yaxis()
ax[1].invert_yaxis()

fig.savefig("%s/mc_ocn_energy%s.png" % (args.output_dir, args.extra_filename), dpi=200)

#plt.show()
