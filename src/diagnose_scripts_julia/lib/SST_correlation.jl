using Statistics
using NCDatasets

using ArgParse
using JSON

include("LinearRegression.jl")

correlation = (x1, x2) -> x1' * x2 / (sum(x1.^2)*sum(x2.^2)).^0.5

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file"
            help = "Ocean data file. New variable will be appended."
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
      
        "--SSTA"
            help = "Variable name of SST."
            arg_type = String
            default = "SSTA"
 
    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

Dataset(parsed["data-file"], "r") do ds

    dims = size(ds[parsed["SSTA"]])

    global SSTA  = nomissing(ds[parsed["SSTA"]][:, :, 1, :], NaN)
    global (Nx, Ny, Nt) = size(SSTA)
    
    if mod(Nt, 12) != 0
        ErrorException("Time record is not multiple of 12") |> throw
    end
    
    global nyears = Int64(Nt / 12)
end

Dataset(parsed["domain-file"], "r") do ds
    global mask = nomissing(ds["mask"][:], NaN)
end

CORR   = zeros(Float64, Nx, Ny, 12)

x = collect(Float64, 1:Nt)
for i=1:Nx, j=1:Ny

    d = view(SSTA, i, j, :)

    if mask[i, j] != 0
        CORR[i, j, :]  .= NaN
        continue
    end
    
    for m = 1:12
        d_yy = view(SSTA, i, j, m:12:(m+nyears*12-1))
        CORR[i, j, m] = correlation(d_yy[1:end-1], d_yy[2:end])
    end
 
end

Dataset(parsed["data-file"], "a") do ds
    if ! haskey(ds.dim, "months")
        defDim(ds, "months", 12)
    end
end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "months", 12)
    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)

    datas =  convert(Array{Any}, [
        ("CORR",  CORR, ("Nx", "Ny", "months"), Dict()),
    ])

    for (varname, vardata, vardim, attrib) in datas
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
