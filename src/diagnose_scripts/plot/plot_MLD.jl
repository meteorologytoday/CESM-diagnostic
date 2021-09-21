include("nanop.jl")

using NCDatasets
using Formatting
using Statistics


Re  = 6371000.0 #  m
c_p  = 1004.0   #  J / kg K
g   = 9.81      #  m / s^2
Lw  = 2.26e6    #  J / kg

linestyle = ["r-", "g-", "b-"]

Dataset("domain_nc_files/domain.lnd.fv4x5_gx3v7.091218.nc", "r") do ds
    global lat, lon, lev, ilev, rec

    lat = replace(ds["yc"][1,:], missing=>NaN)
    lon = replace(ds["xc"][:,1], missing=>NaN)

end


using PyPlot
plt[:rcParams]["font.size"] = 40
plt[:rcParams]["axes.label.size"] = 40

fig, ax = plt[:subplots](1, 1, figsize=(12,8))
#ax[:plot]([-90, 90], [0, 0], linewidth=2, color="#cccccc")

casename = "lowres_SSM_NK"

Dataset("extract_nc_files/$casename.ocn.h.ma.fv4x5.0001-0020.nc", "r") do ds

    t_beg = 240 - 10*12 + 1
    t_end = 240

    cnt_JJA = 0
    cnt_DJF = 0

    mld_JJA = zeros(length(lon), length(lat))
    mld_DJF = zeros(length(lon), length(lat))

    for t = t_beg:t_end
        m = mod(t - 1, 12) + 1

        if m in [11, 12, 1]
            mld_DJF += replace(ds["mld"][:, :, t], missing=>NaN)
            cnt_DJF += 1
        elseif m in [6, 7, 8]
            mld_JJA += replace(ds["mld"][:, :, t], missing=>NaN)
            cnt_JJA += 1
        end
            
    end

    mld_JJA ./= cnt_JJA
    mld_DJF ./= cnt_DJF

    mld_JJA = nanmean(mld_JJA, dims=(1,))[1, :]
    mld_DJF = nanmean(mld_DJF, dims=(1,))[1, :]

    ax[:plot](lat, mld_DJF, "k-", linewidth=2,  label="DJF")
    ax[:plot](lat, mld_JJA, "k--", linewidth=2,  label="JJA")
    
end

ax[:legend](loc="lower center", fontsize=15)
ax[:grid](linestyle="--")
ax[:set_xlabel]("Latitude [deg]", size=15)
ax[:set_ylabel]("Mixed-layer Depth [m]", size=15)
ax[:set_xlim](-90, 90)
ax[:set_ylim](-5, 800)

ax[:invert_yaxis]()

ax[:set_title]("lowres_SSM_NK 11-20 year MLD average in DJF(solid) and JJA(dashed).")

fig[:savefig]("$(casename)_MLD.png", dpi=200)
