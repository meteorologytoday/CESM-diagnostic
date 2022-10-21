include("../src/lib/CESMTools.jl")
using .CESMTools
ct = CESMTools


using Formatting
using NCDatasets
using Statistics

Ψ = nothing

data, Nt = ct.CESMReader2.readData(
    "test_data/qco2_SOM.cam.h0.{:04d}-{:02d}.nc",
    ["PS", "V"],
    (351,  1),
    (355, 12);
    sampling = :annual_mean,
    fixed_varnames = ["P0", "ilev", "lat", "hyai", "hybi"],
    verbose = true,
    conform_dtype = Float32,
)
    
sin_lat = sin.(deg2rad.(data["lat"]))
cos_lat = cos.(deg2rad.(data["lat"]))

for t=1:Nt
    
    global Ψ

    p = ct.calPressure(a=data["hyai"], b=data["hybi"], ps=data["PS"][:, :, t], p0=data["P0"])
    dp = (p[:, :, 2:end, :] - p[ :, :, 1:end-1, :])[:, :, :, 1]

    Ψ_tmp = ct.calStreamfunction(dp=dp, cos_lat=cos_lat, v=data["V"][:, :, :, t])

    if Ψ == nothing
        Ψ = zeros(Float32, size(Ψ_tmp)..., Nt) 
    end

    Ψ[:, :, t] = Ψ_tmp

end

#Ψ = mean(Ψ, dims=3)

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






