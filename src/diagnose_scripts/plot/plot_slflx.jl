using NCDatasets
using Formatting

using Statistics

if length(ARGS) >= 1
    fn = ARGS[1]
end

Re  = 6371000.0 #  m
cp  = 1004.0    #  J / kg K
g   = 9.81      #  m / s^2
Lw  = 2.26e6    #  J / kg

ds = Dataset(fn, "r")

lat = ds["lat"][:] 
lon = ds["lon"][:] 
lev = ds["lev"][:]
ilev = ds["ilev"][:]
rec = ds["time"][:]

deg2rad = π/180.0

#cross_section = (lon[2] - lon[1]) * deg2rad * Re * cos.(lat * deg2rad)

# mass
Δp = (ilev[2:end] - ilev[1:end-1]) * 100.0

function calMeanTransport(v)

    # Get the zonal mean
    v = mean(v, dims=(1,))[1, :, :, :]

    # Weight with mass
    for j=1:length(lat), k=1:length(lev), l=1:length(rec)
        v[j, k, l] *= Δp[k] * cos(lat[j] * deg2rad)
    end

    v .*= 2 * π * Re / g

    # Get the vertical integration and time mean
    v = sum(v, dims=(2,))[:, 1, :]
    v = mean(v, dims=(2,))[:, 1]


    return v
end

# Meridional Static Energy Transport

MHT = cp * ds["VT"][:]  |> calMeanTransport
MGT = ds["VZ"][:]       |> calMeanTransport
MLT = Lw * ds["VQ"][:]  |> calMeanTransport


MMSET = MHT + MGT + MLT
close(ds)

print("Import Pyplot... ")
using PyPlot
println("Done. ")

fig, ax = plt[:subplots](1, 1, figsize=(12,8))

ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc", dashes=(5,3))
ax[:plot](lat, MMSET / 1e15, linewidth=2, "k-",  label="Moist static energy transport")
ax[:plot](lat, MHT   / 1e15, linewidth=2, "k--", label="Heat energy transport")
ax[:plot](lat, MGT   / 1e15, linewidth=2, "r--", label="Geopotential energy transport")
ax[:plot](lat, MLT   / 1e15, linewidth=2, "b--", label="Liquid energy transport")

ax[:legend]()
ax[:set_xlabel]("Latitude [deg]")
ax[:set_ylabel]("[PW]")

ax[:set_title](fn)
ax[:set_xlim](-90, 90)
ax[:set_ylim](-15, 15)



fig[:savefig](fn * ".png", dpi=200)
plt[:close]()


