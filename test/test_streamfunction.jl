include("../src/lib/CESMTools.jl")

using Formatting
using NCDatasets
using .CESMTools


ct = CESMTools



ct.CESMReader2.iterData(
    "test_data/qco2_SOM.cam.h0.{:04d}-{:02d}.nc",
    ["PS", "V"],
    (351,  1),
    (351, 12);
    sampling = :annual_mean,
    fixed_varnames = ["hyai", "hybi", "P0", "lat", "ilev"],
    verbose = true,
    conform_dtype = Float32,
) do d, filenames, skip_cnt
    
    println(format("skip_cnt = {:d}", skip_cnt))
    
    p = ct.calPressure(a=d["hyai"], b=d["hybi"], ps=d["PS"][:, :, 1], p0=d["P0"])
    dp = p[:, :, 1:end-1, :] - p[ :, :, 2:end, :]
    cos_lat = cos.(deg2rad.(d["lat"]))
    


    global Ψ = ct.calStreamfunction(dp=dp[:, :, :, 1], cos_lat=cos_lat, v=d["V"][:, :, :, 1])
    global data = d    
    global sin_lat = sin.(deg2rad.(d["lat"]))
end


println("Loading PyPlot...")
using PyPlot
plt = PyPlot
println("done.")


fig, ax = plt.subplots(1, 1)

Ψ ./= 1e12
Ψ_levs = range(-2, 2, length=11) |> collect
mappable = ax.contourf(sin_lat, data["ilev"], transpose(Ψ), Ψ_levs, cmap="bwr")

plt.colorbar(mappable, ax=ax, ticks=Ψ_levs)
ax.invert_yaxis()


plt.show()






