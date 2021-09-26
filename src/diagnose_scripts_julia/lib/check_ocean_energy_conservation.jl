using Statistics
using NCDatasets

using ArgParse
using JSON
using Formatting

include("LinearRegression.jl")
include("nanop.jl")
include("CESMReader.jl")

using .CESMReader

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
 
        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true
 
        "--output-file"
            help = "Output file."
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

output_file = parsed["output-file"]

if parsed["data-file-timestamp-form"] == "YEAR"
    filename_format = format("{:s}{{:04d}}.nc", joinpath(parsed["data-file-prefix"]))
    form = :YEAR
elseif parsed["data-file-timestamp-form"] == "YEAR_MONTH"
    filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))
    form = :YEAR_MONTH
end
    
Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
    global area = replace(ds["area"], missing=>NaN)
    global Nx, Ny = size(mask)
end

fh = FileHandler(filename_format=filename_format, form=form)
idx = mask.==1
area_valid = area[idx]
sum_area = sum(area_valid)

varnames = ["TFLUX_DIV_implied", "SFLUX_DIV_implied"]

data = Dict()

for varname in varnames
    _tmp_data = reshape( getData(fh, varname, (parsed["beg-year"], parsed["end-year"]), (Colon(), Colon()) ), Nx, Ny, :)

    d = zeros(Float64, size(_tmp_data)[3])
    global Nt = length(d)
    for t = 1:Nt
        d[t] = sum( view(_tmp_data, :, :, t)[idx] .* area_valid ) / sum_area
    end

    global data[varname] = d
end 





Dataset(output_file, "c") do ds

    defDim(ds, "time", Nt)

    for (varname, vardata, vardim, attrib) in (
        ("TFLUX_DIV_implied", data["TFLUX_DIV_implied"], ("time",), Dict()),
        ("SFLUX_DIV_implied", data["SFLUX_DIV_implied"], ("time",), Dict()),
    )
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
