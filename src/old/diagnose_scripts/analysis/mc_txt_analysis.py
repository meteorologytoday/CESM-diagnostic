from netCDF4 import Dataset
import sys, argparse
import numpy as np
from scipy import signal
from pprint import pprint
import os

print("Running file: %s" % __file__)


def mavg(y, span):
 
    N = len(y)
    yy = np.zeros((N,))
    if span == 1:
        yy[:] = y

    else: 
        for i in range(N):
            if i < span:
                rng = slice(0, i+1)
                yy[i] = np.nan
            else:
                rng = slice(i-span,i)
                yy[i] = np.mean(y[rng])
        
    return yy


parser = argparse.ArgumentParser()
parser.add_argument('--input-dir')
parser.add_argument('--output-dir')
parser.add_argument('--casenames')
parser.add_argument('--legends')


args = parser.parse_args()

pprint(args)

casenames = args.casenames.split(",")
legends   = args.legends.split(",")
print("Going to compare these models:")
pprint(casenames)

data = {}

for (i, casename) in enumerate(casenames):

    _data = {} 

    try:

        with Dataset("%s/%s/%s" % (args.input_dir, casenames[i], "atm_analysis7.nc"), "r") as f:
            _data["TREFHT_GLB_mean_temperature"] = np.mean(f.variables["TREFHT_GLB"][:])
            _data["TREFHT_OCN_mean_temperature"] = np.mean(f.variables["TREFHT_OCN"][:])
            _data["TREFHT_LND_mean_temperature"] = np.mean(f.variables["TREFHT_LND"][:])

    except Exception as e:
    
        print("Error happens when doing casename %s. Going to ignore this one..." % casenames[i])

        continue
    
    data[casename] = _data
    


filename = "%s/mc_txt_analysis.txt" % (args.output_dir,)
print("Outputting file: %s ..." % filename, end='')
with open(filename, "w") as f:
    f.write("### TREFHT ###\n")
    f.write("Legend\tCasename\tGLB\tOCN\tLND ###\n")
    for (i, casename) in enumerate(casenames):
        d = data[casename]
        f.write("%s\t%s\t%.2f\t%.2f\t%.2f\n" % (legends[i], casename, d["TREFHT_GLB_mean_temperature"], d["TREFHT_OCN_mean_temperature"], d["TREFHT_LND_mean_temperature"]))


print("done")
