include("../src/lib/CESMTools.jl")
using .CESMTools
ct = CESMTools


using Formatting
using NCDatasets
using Statistics

function findHadleyCellStrength(;
    Ψ        :: Array{T, 2},
    lat      :: Array{T, 1},
    tropical_lat :: T = 30.0,
) where T <: AbstractFloat
    
    valid_lat_idx = abs.(lat) .<= tropical_lat
    subΨ = view(Ψ, valid_lat_idx, :)
    
    maximum(subΨ, ) 
    
end




Ψ = nothing
ct.CESMReader2.iterData(
    "test_data/qco2_SOM.cam.h0.{:04d}-{:02d}.nc",
    ["PS", "V"],
    (351,  1),
    (355, 12);
    sampling = :mean,
    fixed_varnames = ["P0", "ilev", "lat", "hyai", "hybi"],
    verbose = true,
    conform_dtype = Float32,
) do d, filenames, skip_cnt, total_skip_cnt
    
    println(format("skip_cnt = {:d}/{:d}", skip_cnt, total_skip_cnt))
   
    p = ct.calPressure(a=d["hyai"], b=d["hybi"], ps=d["PS"][:, :, 1], p0=d["P0"])
    dp = p[:, :, 2:end, :] - p[ :, :, 1:end-1, :]

    cos_lat = cos.(deg2rad.(d["lat"]))

    Ψ_tmp = ct.calStreamfunction(dp=dp[:, :, :, 1], cos_lat=cos_lat, v=d["V"][:, :, :, 1])

    global Ψ
    if skip_cnt == 1
        Ψ = zeros(Float32, size(Ψ_tmp)..., total_skip_cnt) 
    end
    Ψ[:, :, skip_cnt] = Ψ_tmp

    global data = d    
    global sin_lat = sin.(deg2rad.(d["lat"]))
end

Ψ = mean(Ψ, dims=3)

println("Max of Ψ: ", maximum(Ψ))
println("Min of Ψ: ", minimum(Ψ))


println("Loading PyPlot...")
using PyPlot
plt = PyPlot
println("done.")

Nt = size(Ψ, 3)
fig, ax = plt.subplots(Nt, 1, squeeze=false)

Ψ ./= 1e10
Ψ_levs = range(-10, 10, length=11) |> collect

for t = 1:Nt
    global mappable = ax[t, 1].contourf(sin_lat, data["ilev"], transpose(Ψ[:, :, t]), Ψ_levs, cmap="bwr")
    ax[t, 1].invert_yaxis()
end

plt.colorbar(mappable, ax=ax[end, 1], ticks=Ψ_levs, orientation="horizontal")



plt.show()






