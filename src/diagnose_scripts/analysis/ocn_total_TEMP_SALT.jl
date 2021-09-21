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

function integrate(x, dydx)
    y = copy(dydx) * 0.0

    for i = 2:length(x)
        y[i] = y[i-1] + (dydx[i-1] + dydx[i]) * (x[i] - x[i-1]) / 2.0
    end

    return y
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
            help = "Domain file."
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

    global mask, xc, yc, area, ni, nj
    mask = ds["mask"][:] |> nomissing
    xc   = ds["xc"][:]   |> nomissing
    yc   = ds["yc"][:]   |> nomissing
    area = ds["area"][:] |> nomissing
    ni, nj = size(area)

end

idx       = mask .== 1.0
_area     = area[idx]
_area_sum = sum(_area)

calAreaAvg = ( field , ) -> sum(_area .* (field[idx])) / _area_sum
calAreaWeightedSum = ( field , ) -> sum(_area .* (field[idx]))
function calMonthlyAreaAvg(field)
    return convert(Array{Float64}, [calAreaAvg(view(field, :, :, m)) for m=1:12])
end


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
 
    _TEMP, _SALT = getData(fh, ["TEMP", "SALT"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    global Nt = size(_TEMP)[3]

    if mod(Nt, 12) != 0
        throw(ErrorException("Time should be a multiple of 12."))
    end

    global nyears = Int64(Nt / 12)
    println(format("We got {:d} years of data.", nyears))


    global TEMP = zeros(Float64, Nt)
    global SALT = zeros(Float64, Nt)

    for t=1:Nt
        TEMP[t] = view(_TEMP, :, :, t) |> calAreaWeightedSum
        SALT[t] = view(_SALT, :, :, t) |> calAreaWeightedSum
    end

end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("TEMP",  TEMP,  ("time",), Dict()),
        ("SALT",  SALT,  ("time",), Dict()),
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

















