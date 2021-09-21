import matplotlib.pyplot as plt
import Nio, sys, argparse
import numpy as np
from scipy import signal

def SpectralVariance(y, d=1.0):
    c = np.fft.rfft(signal.detrend(y), norm="ortho") # Ortho means normalized by sqrt N
    return abs(c)**2.0, np.fft.rfftfreq(len(y), d=d)
 
parser = argparse.ArgumentParser()
parser.add_argument('--data-file-PDO')
parser.add_argument('--data-file-AO')
parser.add_argument('--output-dir')
parser.add_argument('--casename')
parser.add_argument('--legend')

args = parser.parse_args()

print(args)

f = Nio.open_file(args.data_file_PDO, "r")
PDO = f.variables["PDO"][:]
f.close()

f = Nio.open_file(args.data_file_AO, "r")
AO = f.variables["AO"][:]
f.close()

N = len(PDO)
time = np.arange(N) / 12
nyears = N / 12.0

PDO /= np.std(PDO)
AO  /= np.std(AO)

PDO_s, freq = SpectralVariance(PDO, d=1.0/12.0)
AO_s, _  = SpectralVariance(AO)

period = 1.0 / freq

marked_periods   = np.array([0.5, 1, 2, 3, 4, 5, 10, 20, 30, 40])

fig, ax = plt.subplots(2, 1, figsize=(12, 10))


ax[0].set_title("[%s] PDO and AO indices (%d years)" % (args.casename, nyears, ))
ax[0].set_xlabel("Time [years]")

ax[0].plot([time[0], time[-1]], [0, 0], "-", color="#cccccc", linewidth=2)
ax[0].plot(time, PDO, "b-", linewidth=2, label="PDO")
ax[0].plot(time, AO, "r--", linewidth=2, label="AO")

ax[0].legend()

ax[1].set_title("Spectrum Analysis")
ax[1].set_xlabel("Period [years]")

ax[1].loglog(period[1:], PDO_s[1:], "b-", linewidth=2, label="PDO")
ax[1].loglog(period[1:], AO_s[1:], "r--", linewidth=2, label="AO")
ax[1].legend()

ax[1].set_xticks(marked_periods)
ax[1].set_xticklabels([("%.1f" if v<1 else "%d") % (v,) for v in marked_periods])

fig.savefig("%s/%s_climate_indices.png" % (args.output_dir, args.casename), dpi=200)

#plt.show()
