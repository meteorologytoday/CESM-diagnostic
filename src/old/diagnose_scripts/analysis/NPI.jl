using Statistics
using NCDatasets

using ArgParse
using JSON

include("nanop.jl")

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file"
            help = "PSLA data file. New variable will be appended."
            arg_type = String
            required = true
 
        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true

      
    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

Dataset(parsed["data-file-SSTA"], "r") do ds

    global SSTA  = replace(ds["SSTA"][:], missing=>NaN)
    global months  = ds.dim["time"]

end

Dataset(parsed["domain-file"], "r") do ds

    global lat  = ds["yc"][:]
    global lon  = ds["xc"][:]

end

# El nino 3.4
# 170W - 120W  => [190 - 240]
# 5S - 5N

EN34idx = (abs.(lat) .<= 5) .& (lon .>= 190) .& (lon .<= 240)

EN34 = zeros(Float64, months)
for i = 1:months

    SSTA_slice = view(SSTA, :, :, i)
    EN34[i] = nanmean(SSTA_slice[EN34idx])

end


Dataset(parsed["data-file-SSTA"], "a") do ds

    for (varname, vardata, vardim, attrib) in [
        ("EN34",  EN34, ("time",), Dict()),
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






