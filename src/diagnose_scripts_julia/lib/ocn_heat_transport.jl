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

include("MapTransform.jl")
include("constants.jl")
include("CESMReader.jl")

using .CESMReader
using .MapTransform

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

#    mask .= 1
    area .*= 4π * Re^2 / sum(area)
end

lat_bnd = collect(Float64, -90:1:90)
r = MapTransform.Relation(
    lat = lat,
    area = area,
    mask = mask,
    lat_bnd = lat_bnd,
)

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
 
    _ADVT, _WKRSTT, _Q_LOST = getData(fh, ["ADVT", "WKRSTT", "Q_LOST"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    Nt = end_t - beg_t + 1

    global ADVT      = zeros(Float64, length(r.lat_bnd)-1, Nt)
    global WKRSTT     = zeros(Float64, length(r.lat_bnd)-1, Nt)
    global WKRSTT_avg = zeros(Float64, Nt)
    global OHT_ADVT  = zeros(Float64, length(r.lat_bnd), Nt)
    global OHT_WKRSTT = zeros(Float64, length(r.lat_bnd), Nt)
    global OHT       = zeros(Float64, length(r.lat_bnd), Nt)

#    @. _WKRSTT += _Q_LOST / ρc

    for t = 1:Nt
        vw_ADVT = view(_ADVT, :, :, t) * ρc
        ADVT[:, t]     = MapTransform.transform(r, vw_ADVT) 
        OHT_ADVT[:, t] = - MapTransform.∫∂a(r, vw_ADVT)
 
        vw_WKRSTT = view(_WKRSTT, :, :, t) * ρc
        WKRSTT[:, t]     = MapTransform.transform(r, vw_WKRSTT)
        WKRSTT_avg[t]    = MapTransform.mean(r, vw_WKRSTT) 
        OHT_WKRSTT[:, t] = - MapTransform.∫∂a(r, (vw_WKRSTT .- WKRSTT_avg[t]))
    end

    global SHF = ADVT + WKRSTT
    global OHT = OHT_ADVT + OHT_WKRSTT

    global years = Int(Nt/12)
    global OHT_AM        = zeros(Float64, length(r.lat_bnd), years)
    global OHT_ADVT_AM   = zeros(Float64, length(r.lat_bnd), years)
    global OHT_WKRSTT_AM  = zeros(Float64, length(r.lat_bnd), years)
    for y = 1:years
        OHT_AM[:, y]       = mean(OHT[:, ((y-1)*12+1):(y*12)], dims=2)[:, 1]
        OHT_ADVT_AM[:, y]  = mean(OHT_ADVT[:, ((y-1)*12+1):(y*12)], dims=2)[:, 1]
        OHT_WKRSTT_AM[:, y] = mean(OHT_WKRSTT[:, ((y-1)*12+1):(y*12)], dims=2)[:, 1]
    end


end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)
    defDim(ds, "year", years)
    defDim(ds, "N1", 1)
    defDim(ds, "lat_bnd", length(r.lat_bnd))
    defDim(ds, "lat",     length(r.lat_bnd)-1)

    ds.attrib["ocean_area"] = sum_valid_area

    for (varname, vardata, vardim, attrib) in [
        ("ADVT",    ADVT,        ("lat", "time"), Dict()),
        ("WKRSTT",   WKRSTT,       ("lat", "time"), Dict()),
        ("WKRSTT_avg",   WKRSTT_avg,       ("time",), Dict()),
        ("SHF",     SHF,         ("lat", "time"), Dict()),
        ("OHT_ADVT",  OHT_ADVT,  ("lat_bnd", "time"), Dict()),
        ("OHT_WKRSTT", OHT_WKRSTT, ("lat_bnd", "time"), Dict()),
        ("OHT",       OHT,       ("lat_bnd", "time"), Dict()),


        ("ADVT_MEAN",  mean(ADVT, dims=2)[:, 1],      ("lat",), Dict()),
        ("WKRSTT_MEAN", mean(WKRSTT, dims=2)[:, 1],     ("lat",), Dict()),
        ("SHF_MEAN",   mean(SHF, dims=2)[:, 1],       ("lat",), Dict()),
        ("OHT_ADVT_MEAN",   mean(OHT_ADVT, dims=2)[:, 1],  ("lat_bnd",), Dict()),
        ("OHT_WKRSTT_MEAN",  mean(OHT_WKRSTT, dims=2)[:, 1], ("lat_bnd",), Dict()),
        ("OHT_MEAN",        mean(OHT, dims=2)[:, 1],       ("lat_bnd",), Dict()),

        ("lat_bnd",          r.lat_bnd,                      ("lat_bnd",), Dict()),
        ("area",             r.∂a,                           ("lat",), Dict()),
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
