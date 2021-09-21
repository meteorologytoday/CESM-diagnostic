using NCDatasets
using Formatting
using PyPlot

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

mass = ((ilev[2:end] - ilev[1:end-1]) / 9.8 * 100.0)'
mass = repeat(mass, outer=(length(lat), ))

mht = view(ds["VT"][:], :, :, :, 1)
mht = view(sum(mht, dims=(1,)), 1, :, :)       # take sum over lon
mht = view(sum(mht .* mass, dims=(2,)), :, 1)  # weight with mass
mht .*= cross_section * cp
close(ds)

mht ./= 1e15

fig, ax = plt[:subplots](1, 1, figsize=(6,4))

ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc", dashes=(5,3))
ax[:plot](lat, mht, linewidth=2, color="black")
ax[:set_xlabel]("Latitude [deg]")
ax[:set_ylabel]("Heat transport [PW]")

ax[:set_title](fn)
ax[:set_xlim](-90, 90)
ax[:set_ylim](-10, 10)

plt[:show]()




