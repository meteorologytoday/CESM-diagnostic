using Formatting
using NCDatasets
using Statistics


Dataset("output_POP2_MOC/processed-MOC_am.nc", "r") do ds
    global AMOC = ds["AMOC_max"][:]
end


println("Loading PyPlot")
using PyPlot
plt = PyPlot
println("Done")

fig, ax = plt.subplots(1, 1, figsize=(6, 4), constrained_layout=true)

t = collect(1:length(AMOC))
ax.plot(t, AMOC)
ax.set_title("AMOC in POP2")
ax.set_ylabel("[ Sv ]")
ax.set_xlabel("Time [ yr ]")

mkpath("figures")
plt.savefig("figures/AMOC_POP2.png", dpi=300)

plt.show()
