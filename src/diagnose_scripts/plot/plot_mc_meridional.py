import matplotlib as mplt
mplt.use('Agg')

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
parser.add_argument('--indexing', default=":")
parser.add_argument('--varname')
parser.add_argument('--yscale', type=float, default=1.0)
parser.add_argument('--ylabel', default="")
parser.add_argument('--extra-title', default="")
parser.add_argument('--extra-filename', default="")
parser.add_argument('--colors')
parser.add_argument('--linestyles', type=str)
parser.add_argument('--y-offset', type=float, default=0.0)

args = parser.parse_args()

pprint(args)

casenames  = args.casenames.split(",")
legends    = args.legends.split(",")
colors     = args.colors.split(",")
linestyles = args.linestyles.split(",")
indexing   = args.indexing.split(",")

indices = []
print("Constructing indexing")
for i, content in enumerate(indexing):
    if content == ":":
        indices.append(slice(None))
    else:
        indices.append(int(content))

indices = tuple(indices)
print("Indices: ", indices)    
    

print("Going to compare these models:")
pprint(casenames)

new_casenames = []
datas = []
for i in range(len(casenames)):

    try:

        f = Dataset("%s/%s/%s" % (args.input_dir, casenames[i], args.data_file), "r")

    except Exception as e:
    
        print("Error happens when doing casename %s. Going to ignore this one..." % casenames[i])

        continue
    
    
    new_casenames.append([casenames[i], legends[i], colors[i], linestyles[i]])
    datas.append((f.variables[args.varname][indices] - args.y_offset) / args.yscale)


    
    f.close()

casenames = new_casenames

f = Dataset(args.domain_file, "r")
lat = f.variables["yc"][:, 1]
f.close()

fig, ax = plt.subplots(1, 1, figsize=(12, 8))

ax.set_title("%s%s" % (args.varname, args.extra_title))
ax.set_xlabel("Latitude [deg]")
ax.set_ylabel(args.ylabel)

for i, (casename, legend, color, linestyle) in enumerate(casenames): 
    ax.plot(lat, datas[i], linewidth=2, label=legend, color=color, linestyle=linestyle)

ax.legend()
ax.grid(True)

fig.savefig("%s/mc_meridional_%s%s.png" % (args.output_dir, args.varname, args.extra_filename), dpi=200)

#plt.show()
