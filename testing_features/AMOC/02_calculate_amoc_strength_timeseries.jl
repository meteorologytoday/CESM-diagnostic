using NCDatasets
using Formatting
using Statistics


input_dir  = "output_POP2_MOC"
output_dir = "output_POP2_MOC"
datafiles = [
    "MOC_am.nc",
]

function mreplace(a)
    return replace(a, missing => NaN)
end

function findAMOCStrength(AMOC, lat, z)

    # find lat index for lat >= 28N
    _, lat28N_idx = findmin( abs.(lat .- 28.0) )
    _, z500m_idx = findmin( abs.(z .- 500) )
    
    lat = lat[lat28N_idx:end]
    z   = z[z500m_idx:end]

    AMOC = AMOC[lat28N_idx:end, z500m_idx:end]

    AMOC_flat = reshape(AMOC, reduce(*, size(AMOC)))
    AMOC_max, AMOC_max_idx = findmax(AMOC_flat)

    lat_max_idx = mod(AMOC_max_idx - 1, length(lat)) + 1
    z_max_idx   = floor(Int64, (AMOC_max_idx - 1) / length(lat)) + 1

    #println(AMOC_max_idx, " => ( ",  lat_max_idx, ", ", z_max_idx, " )")

    lat_max = lat[lat_max_idx]
    z_max = z[z_max_idx]

#=

    if ! ( 28 <= lat_max && 500 <= z_max  )
        println(format("lat_max: {:f}, z_max: {:f}", lat_max, z_max))
        throw(ErrorException("AMOC maximum not within desired z range: north of 28N, deeper than 500m ."))
    end


    if ! ( 30 <= lat_max <= 50 && 600 <= z_max <= 1400  )
        println(format("lat_max: {:f}, z_max: {:f}", lat_max, z_max))
        throw(ErrorException("AMOC maximum not within desired range: 30N-50N, depth 600m-1400m."))
    end
=#

    return AMOC_max, lat_max, z_max
end


mkpath(output_dir)

for datafile in datafiles

    println("Doing file: ", datafile)

    Dataset("$input_dir/$datafile", "r") do ds

        moc_z = ds["moc_z"][:] / 100      |> mreplace
        lat   = ds["lat_aux_grid"][:]     |> mreplace
        AMOC  = ds["MOC"][:, :, 1, 2, :]  |> mreplace



        #years = Int64(size(AMOC)[3] / 12)
        years = Int64(size(AMOC, 3))
        
        AMOC_max     = zeros(Float64, years)
        AMOC_max_lat = zeros(Float64, years)
        AMOC_max_z   = zeros(Float64, years)

        println("years: ", years)

        for y=1:years
            _AMOC = view(AMOC, :, :, y)
            AMOC_max[y], AMOC_max_lat[y], AMOC_max_z[y] = findAMOCStrength(_AMOC, lat, moc_z)
        end

        Dataset(format("$output_dir/processed-{:s}", datafile), "c") do ds
            
            defDim(ds, "time", Inf)
           
            for (varname, vardata, vardim, attrib) in [
                ("AMOC_max",        AMOC_max,     ("time",), Dict()),
                ("AMOC_max_lat",    AMOC_max_lat, ("time",),   Dict()),
                ("AMOC_max_z",      AMOC_max_z,   ("time",), Dict()),
            ]

                if ! haskey(ds, varname)
                    var = defVar(ds, varname, Float64, vardim)
                    var.attrib["_FillValue"] = 1e20
                end

                var = ds[varname]
                
                for (k, v) in attrib
                    var.attrib[k] = v
                end

                rng = []
                for i in 1:length(vardim)-1
                    push!(rng, Colon())
                end
                push!(rng, 1:size(vardata)[end])
                var[rng...] = vardata

            end

        end
        
    end

end
