
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

    area .*= 4π * Re^2 / sum(area)
end

lat_bnd = collect(Float64, -90:1:90) # 181 elements

r = MapTransform.Relation(
    lat = lat,
    area = area,
    mask = mask,
    lat_bnd = lat_bnd,
)

r_aqua = MapTransform.Relation(
    lat = lat,
    area = area,
    mask = mask * 0 .+ 1,
    lat_bnd = lat_bnd,
)


_1flux = area * 0 .+ 1.0
sum_valid_area = MapTransform.∫∂a(r, _1flux)[end]

println("Sum of valid area: ", sum_valid_area, "; ratio: ", sum_valid_area / sum(area))

ocn_frac = MapTransform.f∂a(r, _1flux) ./ MapTransform.f∂a(r_aqua, _1flux)

let
    global TFLUX_DIV_implied, OHT, TSAS_clim, OHT_TSAS_clim, TSAS_clim_mean

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

    Nt = end_t - beg_t + 1

    TFLUX_DIV_implied = zeros(Float64, length(r.lat_bnd)-1, Nt)
    OHT               = zeros(Float64, length(r.lat_bnd)  , Nt)
    TSAS_clim         = zeros(Float64, length(r.lat_bnd)-1, Nt)
    OHT_TSAS_clim     = zeros(Float64, length(r.lat_bnd)  , Nt)
    TSAS_clim_mean    = zeros(Float64, Nt)

 
    TFLUX_DIV, seaice_nudge_energy, _TSAS_clim = getData(fh, ["TFLUX_DIV_implied", "seaice_nudge_energy", "TSAS_clim"], (parsed["beg-year"], parsed["end-year"]), (:, :))

    adjust_TFLUX_DIV = TFLUX_DIV * ρc + seaice_nudge_energy
    for t = 1:Nt
        _data = view(adjust_TFLUX_DIV, :, :, t)
        TFLUX_DIV_implied[:, t] = MapTransform.transform(r, _data) 
        OHT[:, t] = MapTransform.∫∂a(r, _data)
    end

    adjust_TSAS_clim = _TSAS_clim * ρc
    for t = 1:Nt
        _data = view(adjust_TSAS_clim, :, :, t)
        TSAS_clim[:, t] = MapTransform.transform(r, _data)
        TSAS_clim_mean[t] = MapTransform.mean(r, _data) 
        OHT_TSAS_clim[:, t] = - MapTransform.∫∂a(r, _data .- TSAS_clim_mean[t]) 
    end

end






Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)
    defDim(ds, "lat_bnd", length(r.lat_bnd))
    defDim(ds, "lat",     length(r.lat_bnd)-1)
        
    ds.attrib["TSAS_clim_mean_MEAN"] = mean(TSAS_clim_mean)

    for (varname, vardata, vardim, attrib) in [
        ("ocn_frac",          ocn_frac,          ("lat_bnd", ), Dict()),
        ("TFLUX_DIV_implied", TFLUX_DIV_implied, ("lat", "time", ), Dict()),
        ("OHT",               OHT,               ("lat_bnd", "time", ), Dict()),
        ("TSAS_clim",         TSAS_clim,         ("lat", "time", ), Dict()),
        ("TSAS_clim_mean",    TSAS_clim_mean,    ("time", ), Dict()),
        ("OHT_TSAS_clim",     OHT_TSAS_clim,     ("lat_bnd", "time", ), Dict()),
        ("OHT_TOTAL",         OHT + OHT_TSAS_clim,     ("lat_bnd", "time", ), Dict()),

        ("TFLUX_DIV_implied_MEAN", mean(TFLUX_DIV_implied, dims=2)[:, 1],    ("lat",), Dict()),
        ("OHT_MEAN",               mean(OHT, dims=2)[:, 1],                  ("lat_bnd",), Dict()),
        ("TSAS_clim_MEAN",         mean(TSAS_clim, dims=2)[:, 1],            ("lat",), Dict()),
        ("OHT_TSAS_clim_MEAN",     mean(OHT_TSAS_clim, dims=2)[:, 1],        ("lat_bnd",), Dict()),
        ("OHT_TOTAL_MEAN",         mean(OHT + OHT_TSAS_clim, dims=2)[:, 1],  ("lat_bnd",), Dict()),
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

