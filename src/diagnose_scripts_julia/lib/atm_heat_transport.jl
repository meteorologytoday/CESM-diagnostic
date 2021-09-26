#=

Calculation of atmoshpere heat transport is not simple. Detail must be careful.
The standard version I found is here:
    http://www.atmos.albany.edu/facstaff/brose/classes/ATM623_Spring2015/Notes/Lectures/Lecture13%20--%20Heat%20transport.html

In particular, snow flux is not part of latent heat flux so must be added separately.

=#

using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON

include("./lib/map_transform.jl")
include("constants.jl")
include("CESMReader.jl")

using .CESMReader
using .MapTransform

function findITCZ(x, lat)

    j_ITCZ_south = -1

    if length(x) < 2
        throw(ErrorException("Need at least 2 points."))
    end

    if x[1] > 0.0
        throw(ErrorException("ITCZ not within this range: " * string(lat)))
    end

    for j = 2:length(x)
        if x[j] > 0.0  # Found the north one
            j_ITCZ_south = j - 1
            break
        end
    end

    if j_ITCZ_south == -1
        throw(ErrorException("Unable to find ITCZ."))
    end

    if any( x[(j_ITCZ_south + 1):end] .<= 0 )
        println(x) 
        throw(ErrorException("More than two zero flux nodes found."))
    end

    x_south = x[j_ITCZ_south]
    x_north = x[j_ITCZ_south+1]
    lat_south = lat[j_ITCZ_south]
    lat_north = lat[j_ITCZ_south+1]

    return lat_south + (lat_north - lat_south) / (x_north - x_south) * ( 0.0 - x_south)

end


function mreplace(x)
    return replace(x, missing=>NaN)
end

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin
 
        "--data-file-prefix"
            help = "Data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
            arg_type = String
            required = true
 
        "--data-file-timestamp-form"
            help = "Data filename timestamp form. Either `YEAR` or `YEAR_MONTH`."
            arg_type = String
            required = true

        "--output-file"
            help = "Output file."
            arg_type = String
            required = true

        "--domain-file"
            help = "Ocn domain file."
            arg_type = String
            required = true
 
        "--beg-year"
            help = "Year of begin."
            arg_type = Int64
            required = true

        "--end-year"
            help = "Year of end."
            arg_type = Int64
            required = true

    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

Dataset(parsed["domain-file"], "r") do ds
    global area = mreplace(ds["area"][:])
    global mask = mreplace(ds["mask"][:])
    global lat  = mreplace(ds["yc"][:])

    mask .= 1
    area .*= 4π * Re^2 / sum(area)
end

lat_bnd = collect(Float64, -90:1:90)
r = MapTransform.Relation(
    lat = lat,
    area = area,
    mask = mask,
    lat_bnd = lat_bnd,
)

ITCZ_lat_idx = (91-10):(91+10) # 10S ~ 10N
ITCZ_lat_bnd = lat_bnd[ITCZ_lat_idx]


_proxy = area * 0 .+ 1.0
sum_valid_area = MapTransform.∫∂a(r, _proxy)[end]

println("Sum of valid area: ", sum_valid_area, "; ratio: ", sum_valid_area / sum(area))

let

    if parsed["data-file-timestamp-form"] == "YEAR"
        filename_format = format("{:s}{{:04d}}.nc", joinpath(parsed["data-file-prefix"]))
        form = :YEAR
    elseif parsed["data-file-timestamp-form"] == "YEAR_MONTH"
        filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))
        form = :YEAR_MONTH
    end
   
    fh = FileHandler(filename_format=filename_format, form=form)

    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12
 
    FSNT, FLNT, FSNS, FLNS, SHFLX, LHFLX, PRECSC, PRECSL = getData(fh, ["FSNT", "FLNT", "FSNS", "FLNS", "SHFLX", "LHFLX", "PRECSC", "PRECSL"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    # FLX converted to (+) => upward, (-) => downward
    FFLX_TOA = ( - mean(FSNT, dims=(3, ))  + mean(FLNT,  dims=(3, )) )[:, :, 1]
    FFLX_SFC = ( - mean(FSNS, dims=(3, ))  + mean(FLNS,  dims=(3, )) )[:, :, 1]
    HFLX_SFC = (   mean(SHFLX, dims=(3, )) + mean(LHFLX, dims=(3, )) )[:, :, 1]
    PRECS    = (   mean(PRECSC, dims=(3, )) + mean(PRECSL, dims=(3, )) )[:, :, 1]

    FFLX_TOA = ( - FSNT + FLNT )
    FFLX_SFC = ( - FSNS + FLNS )
    HFLX_SFC = ( SHFLX + LHFLX )
    PRECS    = ( PRECSC + PRECSL )


    _data = - ( FFLX_TOA - FFLX_SFC - HFLX_SFC - PRECS * ρ_fw * L_fusion )  # ~ - ∂T/∂t

    Nt = end_t - beg_t + 1

    global TFLX_CONV = zeros(Float64, length(r.lat_bnd)-1, Nt)
    global AHT       = zeros(Float64, length(r.lat_bnd), Nt)

    for t = 1:Nt
        v = view(_data, :, :, t)
        TFLX_CONV[:, t] = MapTransform.transform(r, v) 
        AHT[:, t]       = MapTransform.∫∂a(r, v)
    end

    global years = Int(Nt/12)
    global ITCZ_lat = zeros(Float64, years)
    global AHT_AM   = zeros(Float64, length(r.lat_bnd), years)

    for y = 1:years
        AHT_AM[:, y] = mean(AHT[:, ((y-1)*12+1):(y*12)], dims=2)[:, 1]
        ITCZ_lat[y] = findITCZ(AHT_AM[ITCZ_lat_idx, y], ITCZ_lat_bnd)
    end

end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)
    defDim(ds, "year", years)
    defDim(ds, "lat_bnd", length(r.lat_bnd))
    defDim(ds, "lat",     length(r.lat_bnd)-1)

    for (varname, vardata, vardim, attrib) in [
        ("TFLX_CONV",   TFLX_CONV,                           ("lat", "time"), Dict()),
        ("AHT",        AHT,                                  ("lat_bnd", "time"), Dict()),
        ("TFLX_CONV_MEAN",   mean(TFLX_CONV, dims=2)[:, 1],  ("lat",), Dict()),
        ("AHT_MEAN",         mean(AHT, dims=2)[:, 1],        ("lat_bnd",), Dict()),
        

        ("AHT_AM",           AHT_AM,                         ("lat_bnd", "year",), Dict()),
        ("ITCZ_lat",         ITCZ_lat,                       ("year",), Dict()),
        
        ("lat_bnd",          r.lat_bnd,                      ("lat_bnd",), Dict()),
    ]

        println("Doing var: ", varname)

        var = defVar(ds, varname, Float64, vardim)
        var.attrib["_FillValue"] = 1e20

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
