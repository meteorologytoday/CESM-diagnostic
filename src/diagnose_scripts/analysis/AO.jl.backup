using Statistics
using NCDatasets

using ArgParse
using JSON

include("nanop.jl")

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file-PSLA"
            help = "Ocean PSLA data file. New variable will be appended."
            arg_type = String
            required = true
 
        "--EOF-file-AO"
            help = "Ocean PSLA data file. New variable will be appended."
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

Dataset(parsed["data-file-PSLA"], "r") do ds

    global PSLA  = replace(ds["PSLA"][:], missing=>NaN)
    global months  = ds.dim["time"]

end

Dataset(parsed["EOF-file-AO"], "r") do ds

    global EOF  = replace(ds["EOFs"][:, :, 2], missing=>0.0)

end

EOF /= (sum(EOF .* EOF))^0.5

AO = zeros(Float64, months)

for i = 1:length(AO)
    AO[i] = nansum(EOF .* PSLA[:, :, i]) 
end


Dataset(parsed["data-file-PSLA"], "a") do ds

    for (varname, vardata, vardim, attrib) in [
        ("AO",  AO, ("time",), Dict()),
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






