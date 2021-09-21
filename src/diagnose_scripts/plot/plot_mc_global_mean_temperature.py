import matplotlib.pyplot as plt
import Nio, sys, argparse
import numpy as np
from scipy import signal
from pprint import pprint

def SpectralVariance(y):
    c = np.fft.rfft(signal.detrend(y), norm="ortho") # Ortho means normalized by sqrt N
    return abs(c)**2.0
 
parser = argparse.ArgumentParser()
parser.add_argument('--input-dir', dest='input_dir')
parser.add_argument('--output-dir', dest='output_dir')
parser.add_argument('--casenames', dest='casenames')
parser.add_argument('--legends')
parser.add_argument('--data-file', dest='data_file')
parser.add_argument('--varname', dest='varname')

args = parser.parse_args()

pprint(args)

casenames = args.casenames.split(",")
legends   = args.legends.split(",")

print("Going to compare these models:")
pprint(casenames)

tss = []
sps = []

for i in range(len(casenames)):

    f = Nio.open_file("%s/%s/%s.nc" % (args.input_dir, casenames[i], args.data_file), "r")
    
    ts = f.variables[args.varname][:]
    ts /= np.std(ts)

    sp = SpectralVariance(ts)

    tss.append(ts)
    sps.append(sp)

    f.close()


N = len(tss[0])
freq = np.fft.rfftfreq(N, d=1.0/12.0)
time = np.arange(N) / 12
nyears = N / 12.0
period = 1.0 / freq

marked_periods   = np.array([0.5, 1, 2, 3, 4, 5, 10, 20, 30, 40])

fig, ax = plt.subplots(2, 1, figsize=(12, 10))

ax[0].set_title("%s indices (%d years)" % (args.varname, nyears, ))
ax[0].set_xlabel("Time [years]")
ax[0].plot([time[0], time[-1]], [0, 0], "-", color="#cccccc", linewidth=2)

for i in range(len(casenames)): 
    ax[0].plot(time, tss[i], linewidth=2, label=casenames[i])

ax[0].legend()

ax[1].set_title("Spectrum Analysis")
ax[1].set_xlabel("Period [years]")

for i in range(len(casenames)): 
    ax[1].loglog(period[1:], sps[i][1:], linewidth=2, label=legends[i])
    #ax[1].plot(period[1:], sps[i][1:], linewidth=2, label=casenames[i])

ax[1].legend()

ax[1].set_xticks(marked_periods)
ax[1].set_xticklabels([("%.1f" if v<1 else "%d") % (v,) for v in marked_periods])

fig.savefig("%s/mc_climate_indices_%s.png" % (args.output_dir, args.varname), dpi=200)

#plt.show()
