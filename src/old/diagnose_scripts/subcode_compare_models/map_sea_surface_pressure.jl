### Global surface temperature map


for i = 1:length(casenames)

    fig, ax = plt[:subplots](1, 1, figsize=(12,8))

    casename = casenames[i]
    cmap = plt[:get_cmap]("bwr")
    cmap[:set_over]("r")
    cmap[:set_under]("b")
    cntrs = range(900, step=4, stop=1100)
    Dataset("$nc_file_dir/$casename.h0.nc", "r") do ds

        PSL = mean(mreplace(ds["PSL"][:, :, t_rng]), dims=(3,))[:, :, 1] / 100.0
        #plt[:contourf](lon, lat, mask'[:,:], [.45,.55], cmap=cmap, antialiased=false, extend="both")
        #plt[:contourf](lon, lat, mask'[:,:], [.45,.55], cmap=cmap, antialiased=false, extend="both")
#        cmapping = plt[:contourf](lon, lat, PSL'[:,:], cntrs, cmap=cmap, antialised=true, extend="both")
        plt[:contour](lon, lat, mask'[:,:], [.5], colors="#cccccc")
        cs = plt[:contour](lon, lat, PSL'[:,:], cntrs, antialised=true, colors="k")
        #cs = plt[:contour](lon, lat, TREFHT'[:,:], cntrs, colors="k")
        plt[:clabel](cs, fmt="%d")

        ax[:set_title](format("Mean sea surface pressure ({:d} years): $casename", years))
        ax[:set_xlabel]("Lat [deg]")
        ax[:set_ylabel]("Lon [deg]")
    end

    fig[:savefig]("$(casename)_map_sea_surface_pressure.png", dpi=200)

end
