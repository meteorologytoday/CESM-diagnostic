include("nanop.jl")
include("CESMReader.jl")


using Statistics
using NCDatasets

using ArgParse
using JSON
using Formatting

using .CESMReader


function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--beg-year"
            help = "Year of begin."
            arg_type = Int64
            required = true

        "--end-year"
            help = "Year of end."
            arg_type = Int64
            required = true

        "--data-file-prefix"
            help = "Data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
            arg_type = String
            required = true
 
        "--data-file-timestamp-form"
            help = "Data filename timestamp form. Either `YEAR` or `YEAR_MONTH`."
            arg_type = String
            required = true
 
        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true
 
        "--ilev-file"
            help = "File of pressure levels. Variable assume to be `ilev`."
            arg_type = String
            default = "ilev"


        "--output-file"
            help = "Output file."
            arg_type = String
            required = true

        "--varname"
            help = "Variable name of streamfunction."
            arg_type = String
            required = true

    end

    return parse_args(ARGS, s)
end


parsed = parse_commandline()
print(json(parsed, 4))


function findHadleyCellsStrength(ψ, lat, lev; hemisphere)

    ψ_flat = reshape(ψ, reduce(*, size(ψ)))

    if hemisphere == :NH
        ψ_m, ψ_m_idx = findmax(ψ_flat)
    elseif hemisphere == :SH
        ψ_m, ψ_m_idx = findmin(ψ_flat)
    else
        throw(ErrorException("Unknown keyword: " * string(hemisphere)))
    end


    lat_m_idx = mod(ψ_m_idx - 1, length(lat)) + 1
    lev_m_idx = floor(Int64, (ψ_m_idx - 1) / length(lat)) + 1

    #println(AMOC_max_idx, " => ( ",  lat_max_idx, ", ", z_max_idx, " )")

    lat_m = lat[lat_m_idx]
    lev_m = lev[lev_m_idx]

    if hemisphere == :NH
        if ! ( 0 < lat_m <= 30 && 250 <= lev_m <= 750  )
            println(format("lat_m: {:f}, lev_m: {:f}", lat_m, lev_m))
            throw(ErrorException("ψ maximum not within desired range."))
        end
    elseif hemisphere == :SH
        if ! ( -30 <= lat_m < 0 && 250 <= lev_m <= 750  )
            println(format("lat_m: {:f}, lev_m: {:f}", lat_m, lev_m))
            throw(ErrorException("ψ maximum not within desired range."))
        end
    end

    return ψ_m, lat_m, lev_m
end


Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
    global lat  = replace(ds["yc"][1, :], missing=>NaN)
    global Ny = length(lat)
end

Dataset(parsed["ilev-file"], "r") do ds
    global ilev = replace(ds["ilev"], missing=>NaN)
    global Nz = length(ilev)
end

if parsed["data-file-timestamp-form"] == "YEAR"

    filename_format = format("{:s}{{:04d}}.nc", joinpath(parsed["data-file-prefix"]))
    form = :YEAR
elseif parsed["data-file-timestamp-form"] == "YEAR_MONTH"
    filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))
    form = :YEAR_MONTH
end

global beg_t = (parsed["beg-year"] - 1) * 12 + 1
global end_t = (parsed["end-year"] - 1) * 12 + 12
global Nt = end_t - beg_t + 1

fh = FileHandler(filename_format=filename_format, form=form)
ψ = reshape( getData(fh, parsed["varname"], (parsed["beg-year"], parsed["end-year"]), (:, :)), Ny, Nz, Nt)

#Dataset(parsed["data-file"], "r") do ds
#    global ψ = reshape(replace(ds[parsed["varname"]][:], missing=>NaN), Ny, Nz, :)
#    global Nt = size(ψ)[3]
#end

years = Int64(Nt/12)

hadleycell_north_max = zeros(Float64, years)
hadleycell_north_max_lat = zeros(Float64, years)
hadleycell_north_max_lev = zeros(Float64, years)

hadleycell_south_max = zeros(Float64, years)
hadleycell_south_max_lat = zeros(Float64, years)
hadleycell_south_max_lev = zeros(Float64, years)




for y=1:years
    _ψ = mean( view(ψ, :, :, ((y-1)*12+1):(y*12)), dims=3 )[:, :, 1]
    hadleycell_north_max[y], hadleycell_north_max_lat[y], hadleycell_north_max_lev[y] = findHadleyCellsStrength(_ψ, lat, ilev; hemisphere=:NH)
    hadleycell_south_max[y], hadleycell_south_max_lat[y], hadleycell_south_max_lev[y] = findHadleyCellsStrength(_ψ, lat, ilev; hemisphere=:SH)
end

println(hadleycell_south_max)

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in  [

        ("hadleycell_north_max",     hadleycell_north_max,     ("time",), Dict()),
        ("hadleycell_north_max_lat", hadleycell_north_max_lat, ("time",), Dict()),
        ("hadleycell_north_max_lev", hadleycell_north_max_lev, ("time",), Dict()),

        ("hadleycell_south_max",     hadleycell_south_max,     ("time",), Dict()),
        ("hadleycell_south_max_lat", hadleycell_south_max_lat, ("time",), Dict()),
        ("hadleycell_south_max_lev", hadleycell_south_max_lev, ("time",), Dict()),

    ]
        if ! haskey(ds, varname)
            var = defVar(ds, varname, Float64, vardim)
            var.attrib["_FillValue"] = 1e20
        end

        println("Writing variable:  ", varname)
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
