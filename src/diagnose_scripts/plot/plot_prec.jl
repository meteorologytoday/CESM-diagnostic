using NCDatasets
using Formatting
using PyPlot
using Statistics

if length(ARGS) >= 1
    fn = ARGS[1]
end

const Re = 6371000.0 
const cp = 1004.0

ds = Dataset(fn, "r")

lat = ds["lat"][:] 
lon = ds["lon"][:] 
lev = ds["lev"][:]
ilev = ds["ilev"][:]

deg2rad = π/180.0

cross_section = (lon[2] - lon[1]) * deg2rad * Re * cos.(lat * deg2rad)

tot_prec = ds["PRECC"][:] + ds["PRECL"][:]
tot_prec = view(tot_prec, :, :, 1)
tot_prec = view(mean(tot_prec, dims=(1,)), 1, :)       # take sum over lon
close(ds)


fig, ax = plt[:subplots](1, 1, figsize=(6,4))

ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc", dashes=(5,3))
ax[:plot](lat, tot_prec * 86400.0 * 365 * 1000.0, linewidth=2, color="black")
ax[:set_xlabel]("Latitude [deg]")
ax[:set_ylabel]("Annual Precipiation [mm / yr]")

ax[:set_title](fn)
ax[:set_xlim](-90, 90)
ax[:set_ylim](-100, 2500)

plt[:show]()




