using Formatting
using NCDatasets
using Statistics
include(joinpath("..", "CESM-diagnostic", "src", "diagnose_scripts_julia", "lib", "CESMReader.jl"))

using .CESMReader

ρcp = 3996 * 1026.0

function m2a(ts)
    return mean(reshape(ts, 12, :), dims=(1,))[1, :]
end

include("setup.jl")

data_dir = "output"

data = Dict()
models = ["SOM", "MLM", "EMOM", "POP2"]
models = ["SOM", "EMOM", "POP2"]

year_skip = 10


R = 6.371e6 # meters.
H = 10.0    # meters. only 1 grid

Dataset(domain_files["ocn"], "r") do ds

    global area = ds["area"][:]
    global mask = ds["mask"][:]
    global lat  = ds["yc"][:]

    area .*= 4π * (R^2) / sum(area)

    global _area = reshape(area, size(area)... , 1)
    global mask_NH_idx = (mask .== 1) .& (lat .>= 0)
    global mask_SH_idx = (mask .== 1) .& (lat .<  0)

    global NH_area = sum(area[mask_NH_idx])
    global SH_area = sum(area[mask_SH_idx])
end

for (casename, caseinfo) in cases
    

    d = Dict()

    fh = FileHandler(filename_format="$data_dir/$casename/ocn/$casename.ocn.sfc.{:04d}.nc", form=:YEAR_MONTH)

    yrng = caseinfo["yrng"]
    time_vec = [(y, 1) for y = yrng[1]:year_skip:yrng[2]]

    TEMP = CESMReader._getData(fh, "TEMP", time_vec, (:, :) ) 
    
#    TEMP = ρcp .* _area .* TEMP 
    TEMP = _area .* TEMP

    TEMP[isnan.(TEMP)] .= 0

    TEMP_NH = zeros(Float64, size(TEMP, 3))
    TEMP_SH = zeros(Float64, size(TEMP, 3))
        
    for t=1:length(TEMP_NH)
        TEMP_NH[t] = sum(view(TEMP, :, :, t)[mask_NH_idx]) / NH_area / H
        TEMP_SH[t] = sum(view(TEMP, :, :, t)[mask_SH_idx]) / SH_area / H
    end

    #TEMP = sum(TEMP, dims=(1, 2))[1, 1, :] * ρcp

    data[casename] = Dict(
        "TEMP"    => TEMP_NH + TEMP_SH,
        "TEMP_NH" => TEMP_NH,
        "TEMP_SH" => TEMP_SH,
    )

end

println("Loading PyPlot")
using PyPlot
plt = PyPlot
println("Done")

fig, ax = plt.subplots(2, 1, figsize=(6, 8), constrained_layout=true)

for (casename, caseinfo) in cases
    
    d = data[casename]
    t = collect(1:length(d["TEMP"]))

    ax[1].plot(t, d["TEMP_NH"], label=casename)
    ax[2].plot(t, d["TEMP_SH"], label=casename)

end

ax[1].legend()

ax[1].set_title("NH SST")
ax[2].set_title("SH SST")

for _ax in ax
    _ax.set_ylabel("[\$ {}^\\circ\\mathrm{C} \$]")
    _ax.set_xlabel("Time [ yr ]")
end


mkpath("figures")
plt.savefig("figures/ocean_SST.png", dpi=300)

plt.show()
