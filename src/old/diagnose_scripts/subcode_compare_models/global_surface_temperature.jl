### Global surface temperature map


for i = 1:length(casenames)

    fig, ax = plt[:subplots](1, 1, figsize=(12,8))

#=
    m = basemap.Basemap(projection="merc",llcrnrlat=-80,urcrnrlat=80,
                llcrnrlon=0,urcrnrlon=360,lat_ts=20,resolution="c",lon_0=180.0, ax=ax)

    lab_lons = collect(0:30:360)
    lab_lats = collect(-90:30:90)


    m[:drawcoastlines](linewidth=1.5)
    m[:fillcontinents](color="#888888", lake_color="aqua")
    m[:drawmeridians](lab_lons, labels=repeat([true, ], outer=(length(lab_lons),)))
    m[:drawparallels](lab_lats, labels=repeat([true, ], outer=(length(lab_lats),)))
=#
    casename = casenames[i]
    cmap = plt[:get_cmap]("bwr")
    cmap[:set_over]("r")
    cmap[:set_under]("b")
    cntrs = range(-30, step=5, stop=30)
    Dataset("$nc_file_dir/$casename.h1.nc", "r") do ds

        TREFHT = mean(mreplace(ds["TREFHT"][:, :, t_rng]), dims=(3,))[:, :, 1] .- 273.15
        #plt[:contourf](lon, lat, mask'[:,:], [.45,.55], cmap=cmap, antialiased=false, extend="both")
        #plt[:contourf](lon, lat, mask'[:,:], [.45,.55], cmap=cmap, antialiased=false, extend="both")
        cmapping = plt[:contourf](lon, lat, TREFHT'[:,:], cntrs, cmap=cmap, antialised=true, extend="both")
        plt[:contour](lon, lat, mask'[:,:], [.5], colors="#000000")
        #cs = plt[:contour](lon, lat, TREFHT'[:,:], cntrs, colors="k")
        #plt[:clabel](cs, fmt="%d")
        cba = plt[:colorbar](cmapping, ax=ax)

        ax[:set_title](format("Mean surface temperature ({:d} years): $casename", years))
        ax[:set_xlabel]("Lat [deg]")
        ax[:set_ylabel]("Lon [deg]")
        cba[:set_label]("Temperature [degC]")
    end

    fig[:savefig]("$(casename)_map_surface_temperature.png", dpi=200)

end
