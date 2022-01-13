using NCDatasets
using Formatting

using Statistics

Re  = 6371000.0 #  m
c_p  = 1004.0    #  J / kg K
g   = 9.81      #  m / s^2
Lw  = 2.26e6    #  J / kg

t_beg = 240-10*12+1
t_end = 240
t_rng = t_beg:t_end
years = (t_end - t_beg + 1) / 12.0
nc_file_dir = "extract_nc_files"
domain_nc_file_dir = "domain_nc_files"

casenames = [
    "lowres_STD_SOM",
    "lowres_SSM_SOM",
    "lowres_SSM_NK",
    "lowres_SSM_SOM_noQflux",
]
    
linestyle = ["k-", "r-", "g-", "b-"]

mreplace = (x,) -> replace(x, missing=>NaN)

Dataset("$domain_nc_file_dir/domain.lnd.fv4x5_gx3v7.091218.nc", "r") do ds
    global mask
    mask = ds["mask"][:] |> mreplace
    
    mask[mask.!=0] .= 1
end



Dataset("$nc_file_dir/$(casenames[1]).h1.nc", "r") do ds
    global lat, lon, lev, ilev, rec

    lat = ds["lat"][:] |> mreplace
    lon = ds["lon"][:] |> mreplace

    ilev = (ds["ilev"][:] |> mreplace) * 100.0

    rec = ds["time"][:] |> mreplace

    lev = (ilev[2:end] + ilev[1:end-1]) / 2.0
end

# mass
Δp = (ilev[2:end] - ilev[1:end-1])


function calMeanTransport(v)

    # Get the zonal mean
    v = mean(v, dims=(1,))[1, :, :, :]

    # Weight with mass
    for j=1:length(lat), k=1:length(lev), l=1:length(rec)
        v[j, k, l] *= Δp[k] * cos(lat[j] |>  deg2rad)
    end

    v .*= 2 * π * Re / g

    # Get the vertical integration and time mean
    v = sum(v, dims=(2,))[:, 1, :]
    v = mean(v, dims=(2,))[:, 1]


    return v
end

function integrate(x, dydx)
    y = copy(dydx) * 0.0

    for i = 2:length(x)
        y[i] = y[i-1] + (dydx[i-1] + dydx[i]) * (x[i] - x[i-1]) / 2.0
    end

    return y
end


print("Import Pyplot... ")
using PyPlot
plt[:rcParams]["font.size"] = 20

#using PyCall
#@pyimport mpl_toolkits.basemap as basemap

println("Done. ")

#include("subcode_compare_models/global_surface_temperature.jl")
#include("subcode_compare_models/map_sea_surface_pressure.jl")
include("subcode_compare_models/map_SST.jl")

#=
### Streamfunction

include(joinpath(@__DIR__, "invert_streamfunction.jl"))

fig_compare, ax_compare = plt[:subplots](1, 1, figsize=(12,8))
ax_compare[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc")

for i = 1:length(casenames)

    casename = casenames[i]

    fig, ax = plt[:subplots](1, 1, figsize=(12,8))
    
    Dataset("$nc_file_dir/$casename.h0.nc", "r") do ds

        global V = mean(replace(ds["V"][:], missing=>NaN), dims=(1, 4))[1, :, :, 1]
        ψ  = invertStreamfunction(lat * π / 180.0, ilev, V; g0=g, Re=Re) / 1e10

        println(size(ψ), ";", size(lat), ";", size(ilev))
        cs = ax[:contour](lat, ilev/100, ψ'[:,:], range(-20, step=2, stop=20), colors="k")


        ax[:clabel](cs, fmt="%d")
        ax[:set_xlabel]("Lat [deg]")
        ax[:set_ylabel]("Pressure [hPa]")

        ax[:set_title](casename)
        ax[:set_xlim](-90, 90)
        ax[:set_ylim](100, 1000)
        ax[:invert_yaxis]()

        fig[:savefig]("$(casename)_psi.png", dpi=200)


        ax_compare[:plot](lat, mean(ψ[:, 19:20], dims=(2,))[:,1], linestyle[i], label="$casename")

    end


end

ax_compare[:legend]()
ax_compare[:set_xlabel]("Lat [deg]")
ax_compare[:set_ylabel]("Streamfunction [ \$ \\times 10^{10} \$ kg / s]")

ax_compare[:set_title]("Streamfunction along 510 hPa (meridional mass transport below 510 hPa)")
ax_compare[:set_xlim](-90, 90)

fig_compare[:savefig]("compare_models_psi.png", dpi=200)

=#



#=

### Meridional Static Energy Transport

fig, ax = plt[:subplots](1, 1, figsize=(12,8))

ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc")

for i = 1:length(casenames)

    casename = casenames[i]

    Dataset(casename * ".nc", "r") do ds
        global MHT, MGT, MLT
        MHT = c_p * ds["VT"][:]  |> calMeanTransport
        MGT = ds["VZ"][:]       |> calMeanTransport
        MLT = Lw * ds["VQ"][:]  |> calMeanTransport

    end

    MMSET = (MHT + MGT + MLT) / 1e15


    ax[:plot](lat, MMSET, linestyle[i], linewidth=2,  label=casename)

end

ax[:legend]()
ax[:set_xlabel]("Latitude [deg]")
ax[:set_ylabel]("[PW]")

ax[:set_title]("10 years")
ax[:set_xlim](-90, 90)
ax[:set_ylim](-15, 20)

fig[:savefig]("compare_models_MSEFLX.png", dpi=200)



### Precipitation
fig, ax = plt[:subplots](1, 1, figsize=(12,8))

ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc")

for i = 1:length(casenames)

    casename = casenames[i]

    Dataset(casename * ".nc", "r") do ds
        global tot_prec = replace(ds["PRECC"][:] + ds["PRECL"][:], missing=>NaN)

        tot_prec = mean(tot_prec, dims=(1,3))[1, :, 1] # average over time and longitude
    end

    ax[:plot](lat, tot_prec * 365.0 * 86400.0 * 1000.0, linestyle[i], linewidth=2,  label=casename)
end

ax[:legend]()
ax[:set_xlabel]("Latitude [deg]")
ax[:set_ylabel]("Precipitation [mm / yr]")

ax[:set_title]("10 years")
ax[:set_xlim](-90, 90)
#ax[:set_ylim](, 20)

fig[:savefig]("compare_models_PRECIP.png", dpi=200)


### Energy convergence


fig_met, ax_met = plt[:subplots](1, 1, figsize=(12,8))
ax_met[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc")

for i = 1:length(casenames)

    fig, ax = plt[:subplots](1, 1, figsize=(12,8))
    ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc")

    casename = casenames[i]

    Dataset(casename * ".h0.nc", "r") do ds
        t_rng = (:, :,  240-5*12+1:240)
        FFLX_TOA = mean( - mean(ds["FSNT"][t_rng...], dims=(3,)) + mean(ds["FLNT"][t_rng...], dims=(3,)), dims=(1,))[1, :, 1]
        FFLX_SFC = mean( - mean(ds["FSNS"][t_rng...], dims=(3,)) + mean(ds["FLNS"][t_rng...], dims=(3,)), dims=(1,))[1, :, 1]
        HFLX_SFC = mean( mean(ds["SHFLX"][t_rng...], dims=(3,)) + mean(ds["LHFLX"][t_rng...], dims=(3,)), dims=(1,))[1, :, 1]
       

        FFLX_TOA .*= Re * cos.(deg2rad.(lat)) * 2π 
        FFLX_SFC .*= Re * cos.(deg2rad.(lat)) * 2π
        HFLX_SFC .*= Re * cos.(deg2rad.(lat)) * 2π
 
        EFLX_CONV = - ( FFLX_TOA - FFLX_SFC - HFLX_SFC )


        
        ax[:plot](lat, FFLX_TOA, "r--", linewidth=2,  label="FTOA")
        ax[:plot](lat, FFLX_SFC, "b--", linewidth=2,  label="FSFC")
        ax[:plot](lat, HFLX_SFC, "g--", linewidth=2,  label="HFLX")
        ax[:plot](lat, EFLX_CONV, "k-", linewidth=2,  label="CONV")
        
        MET = integrate(Re * deg2rad.(lat), EFLX_CONV)
        ax_met[:plot](lat, MET / 1e15, linestyle[i], linewidth=2, label=casename)

    end

    ax[:legend]()
    ax[:set_xlabel]("Latitude [deg]")
    ax[:set_ylabel]("[PW / m]")

    ax[:set_title](format("10 years in case {}", casename))
    ax[:set_xlim](-90, 90)

    fig[:savefig](format("compare_models_EBM_{}.png", casename), dpi=200)



end

ax_met[:legend]()
ax_met[:set_xlabel]("Latitude [deg]")
ax_met[:set_ylabel]("[PW]")

ax_met[:set_title](format("16-20 years annual implied northward heat transport"))
ax_met[:set_xlim](-90, 90)
ax_met[:set_ylim](-6, 6)

fig_met[:savefig](format("compare_models_MET.png"), dpi=200)


#ax[:set_ylim](-15, 20)



### Temperature trend

fig, ax = plt[:subplots](1, 1, figsize=(12,8))


dθ = deg2rad(lat[2] - lat[1])
for i = 1:length(casenames)

    casename = casenames[i]

    Dataset(casename * ".h1.nc", "r") do ds

        TREFHT = sum(mean(ds["TREFHT"][:], dims=(1,)), dims=(1,) )[1, :, :]
        Tavg = zeros(Float64, length(rec))
        for l = 1:length(rec)
            TREFHT[:, l] .*= cos.(deg2rad.(lat))
            Tavg[l] = sum(TREFHT[:, l]) * dθ / 2.0
        end

        Tavg .-= 273.15

        ax[:plot](collect(Float64, 0:length(rec)-1) / 365.0, Tavg, linestyle[i], linewidth=2,  label=casename)
    end

end

ax[:legend]()
ax[:set_xlabel]("Time [month]")
ax[:set_ylabel]("Temperature")

ax[:set_title]("Global Mean surface temperature of 20 years")
ax[:set_xlim](0, 20)
ax[:set_ylim](0, 20)

fig[:savefig]("compare_models_ECNVG.png", dpi=200)


=#
