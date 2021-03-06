
using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON

include("constants.jl")
include("CESMReader.jl")

using .CESMReader

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

        "--raw"
            help = "If set, then aice and vice will be computed from the data. I.e. summing from cat 1 to cat 5"
            action = :store_true


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

    global idx_GLB = ( mask .== 1.0 )
    global idx_NH  = ( mask .== 1.0 ) .& ( lat .>= 0.0 )
    global idx_SH  = ( mask .== 1.0 ) .& ( lat .<  0.0 )

end

function calAreaWeightedSum(v, idx)

#    println("size(area): ", size(area))
#    println("size(v): ", size(v))
#    println("size(idx): ", size(idx))


    return sum( area[idx] .* v[idx] )
end

function calAreaWeightedSumTimeseries(v, idx)
    return [ calAreaWeightedSum( view(v, :, :, t), idx ) for t=1:size(v)[3] ]
end


let
    global ice_volume_GLB, ice_volume_NH, ice_volume_SH
    global ice_area_GLB, ice_area_NH, ice_area_SH
    global ice_extent_GLB, ice_extent_NH, ice_extent_SH

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
 
    if parsed["raw"]

        varnames = []
        for v in ["vice", "aice"]
            for k = 1:5
                push!(varnames, format("{:s}n{:03d}", v, k))
            end
        end

        vice1, vice2, vice3, vice4, vice5, aice1, aice2, aice3, aice4, aice5 = getData(fh, varnames, (parsed["beg-year"], parsed["end-year"]), (:, :))

        vice = vice1 + vice2 + vice3 + vice4 + vice5
        aice = aice1 + aice2 + aice3 + aice4 + aice5

    else
        vice, aice = getData(fh, ["vice", "aice"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    end

    aice_extent = zeros(Float64, size(aice)...)
    aice_extent[aice .>= 0.15] .= 1.0

    ice_volume_GLB = calAreaWeightedSumTimeseries(vice, idx_GLB)
    ice_volume_NH  = calAreaWeightedSumTimeseries(vice, idx_NH)
    ice_volume_SH  = calAreaWeightedSumTimeseries(vice, idx_SH)

    ice_area_GLB = calAreaWeightedSumTimeseries(aice, idx_GLB)
    ice_area_NH  = calAreaWeightedSumTimeseries(aice, idx_NH)
    ice_area_SH  = calAreaWeightedSumTimeseries(aice, idx_SH)

    ice_extent_GLB = calAreaWeightedSumTimeseries(aice_extent, idx_GLB)
    ice_extent_NH  = calAreaWeightedSumTimeseries(aice_extent, idx_NH)
    ice_extent_SH  = calAreaWeightedSumTimeseries(aice_extent, idx_SH)


end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("ice_volume_GLB", ice_volume_GLB, ("time",), Dict()),
        ("ice_volume_NH",  ice_volume_NH,  ("time",), Dict()),
        ("ice_volume_SH",  ice_volume_SH,  ("time",), Dict()),
        ("ice_area_GLB",   ice_area_GLB,   ("time",), Dict()),
        ("ice_area_NH",    ice_area_NH,    ("time",), Dict()),
        ("ice_area_SH",    ice_area_SH,    ("time",), Dict()),
        ("ice_extent_GLB", ice_extent_GLB, ("time",), Dict()),
        ("ice_extent_NH",  ice_extent_NH,  ("time",), Dict()),
        ("ice_extent_SH",  ice_extent_SH,  ("time",), Dict()),
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

