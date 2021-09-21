### Global surface temperature map


for i = 1:length(casenames)

    fig, ax = plt[:subplots](1, 1, figsize=(12,8))

    casename = casenames[i]

    if match(r"STD", casename) != nothing
        continue
    end

    cmap = plt[:get_cmap]("coolwarm")
    cmap[:set_over]("r")
    cmap[:set_under]("b")
    cntrs = range(-2, step=2, stop=30)

    Dataset("$nc_file_dir/$casename.ocn.h.ma.fv4x5.0001-0020.nc", "r") do ds

        println(ds.dim["time"])

        if match(r"SSM_NK", casename) != nothing
            T_ML = ds["T"][:, :, 1, t_rng]
        elseif match(r"SSM_SOM", casename) != nothing
            T_ML = ds["T_ML"][:, :, t_rng]
        end
    
        T_ML = mreplace(T_ML)
        T_ML = mean(T_ML, dims=(3,))[:, :, 1] .- 273.15
        
        cmapping = plt[:contourf](lon, lat, T_ML'[:,:], cntrs, cmap=cmap, antialised=true, extend="both")

        #ax[:contour](lon, lat, mask'[:,:], [.5], colors="#000000")

        cba = plt[:colorbar](cmapping, ax=ax)

        ax[:set_title](format("Mean SST ({:d} years): $casename", years))
        ax[:set_xlabel]("Lat [deg]")
        ax[:set_ylabel]("Lon [deg]")
        cba[:set_label]("Temperature [degC]")
    end

    fig[:savefig]("$(casename)_map_SST.png", dpi=200)

end
