import matplotlib as mplt
mplt.use('Agg')

import matplotlib.pyplot as plt
import netCDF4, sys, argparse
import numpy as np
from scipy import signal
from pprint import pprint

def mavg(y, span):
 
    N = len(y)
    yy = np.zeros((N,))
    for i in range(N):
        if i >= span - 1:
            rng = slice(i-span+1,i+1)
            yy[i] = np.mean(y[rng])
        else:
            yy[i] = np.nan

    return yy


def SpectralVariance(y):
    c = np.fft.rfft(y, norm="ortho") # Ortho means normalized by sqrt N
    return abs(c)**2.0
 
parser = argparse.ArgumentParser()
parser.add_argument('--input-dir')
parser.add_argument('--output-dir')
parser.add_argument('--casenames')
parser.add_argument('--legends')
parser.add_argument('--data-file')
parser.add_argument('--varname')
parser.add_argument('--normalize', default="yes")
parser.add_argument('--logy_max', type=float, default=3)
parser.add_argument('--logy_min', type=float, default=-3)
parser.add_argument('--ylabel', default="")
parser.add_argument('--colors')
parser.add_argument('--linestyles')
parser.add_argument('--t-offset', type=float, default=0.0)
parser.add_argument('--mavg', type=int, default=1)

args = parser.parse_args()

pprint(args)

casenames = args.casenames.split(",")
legends   = args.legends.split(",")
colors    = args.colors.split(",")
linestyles = args.linestyles.split(",")

print("Going to compare these models:")
pprint(casenames)

tss = []
sps = []

new_casenames = []

for i in range(len(casenames)):

    try:

        f = netCDF4.Dataset("%s/%s/%s" % (args.input_dir, casenames[i], args.data_file), "r")

    except Exception as e:
    
        print("Error happens when doing casename %s. Going to ignore this one..." % casenames[i])

        continue
    
    
    new_casenames.append([casenames[i], legends[i], colors[i], linestyles[i]])

    ts = f.variables[args.varname][:]


    if args.normalize == "yes":
        ts = signal.detrend(ts)
        ts /= np.std(ts)

    ts = mavg(ts, args.mavg)[args.mavg-1:]

    sp = SpectralVariance(ts)

    tss.append(ts)
    sps.append(sp)

    f.close()

casenames = new_casenames

N = len(tss[0])
freq = np.fft.rfftfreq(N, d=1.0/12.0)
time = (np.arange(N) + args.mavg - 1) / 12 + args.t_offset
nyears = (N+(args.mavg-1)) / 12.0
period = 1.0 / freq

marked_periods   = np.array([0.5, 1, 2, 3, 4, 5, 6,7,8,9, 10, 15, 20, 30, 40])

fig, ax = plt.subplots(3, 1, figsize=(15, 10))

ax[0].set_title("%s (%d years)" % (args.varname, nyears, ))
ax[0].set_xlabel("Time [years]")
ax[0].set_ylabel(args.ylabel)
ax[0].grid()
for i, (casename, legend, color, linestyle) in enumerate(casenames): 
    ax[0].plot(time, tss[i], linewidth=2, label=legend, color=color, linestyle=linestyle)

ax[0].legend()

ax[1].set_title("Spectrum Analysis")
ax[1].set_xlabel("Period [years]")
ax[1].set_ylabel("Intensity  $| \\hat{c}(\\omega) |^2$")
ax[1].grid()

for i, (casename, legend, color, linestyle) in enumerate(casenames): 
    ax[1].loglog(period[1:], sps[i][1:], linewidth=2, label=legend, color=color, linestyle=linestyle)

ax[1].legend()

ax[1].set_xticks(marked_periods)
ax[1].set_xticklabels([("%.1f" if v<1 else "%d") % (v,) for v in marked_periods])

ax[1].set_ylim([10**args.logy_min, 10**args.logy_max])


ax[2].set_title("Spectrum Analysis")
ax[2].set_xlabel("Period [years]")
ax[2].set_ylabel("Intensity  $| \\hat{c}(\\omega) |^2$")
ax[2].grid()

for i, (casename, legend, color, linestyle) in enumerate(casenames): 
    ax[2].plot(np.log(period[1:]), sps[i][1:], linewidth=2, label=legend, color=color, linestyle=linestyle)

ax[2].legend()

ax[2].set_xticks(np.log(marked_periods))
ax[2].set_xticklabels([("%.1f" if v<1 else "%d") % (v,) for v in marked_periods])

#ax[2].set_ylim([10**args.logy_min, 10**args.logy_max])


fig.savefig("%s/mc_climate_indices_%s.png" % (args.output_dir, args.varname), dpi=200)

#plt.show()
