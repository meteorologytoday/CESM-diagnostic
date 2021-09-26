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
            help = "Atm data file. New variable will be appended."
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

Dataset(parsed["data-file"], "r") do ds

    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12
    rng = (:,:,beg_t:end_t) 
 
    global total_precip = replace(ds["PRECC"][rng...] + ds["PRECL"][rng...], missing=>NaN)
    global (Nx, Ny, Nt) = size(total_precip)
    
    if mod(Nt, 12) != 0
        ErrorException("Time record is not multiple of 12") |> throw
    end
    
    global nyears = Int64(Nt / 12)
end

Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
end

# M   = Mean
# VAR = Variance

# MM   = Monthly Mean
# MVAR = Monthly Variance

# ZM   = Zonal Mean
# ZVAR = Zonal Variance

# ZMM   = Zonal Monthly Mean
# ZMVAR = Zonal Monthly Variance

total_precip_M     = zeros(Float64, Nx, Ny)
total_precip_VAR   = zeros(Float64, Nx, Ny)

total_precip_MM     = zeros(Float64, Nx, Ny, 12)
total_precip_MVAR   = zeros(Float64, Nx, Ny, 12)

total_precip_ZM     = zeros(Float64, Ny)
total_precip_ZVAR   = zeros(Float64, Ny)

total_precip_ZMM    = zeros(Float64, Ny, 12)
total_precip_ZMVAR  = zeros(Float64, Ny, 12)


x = collect(Float64, 1:Nt)
for i=1:Nx, j=1:Ny

    d = view(total_precip, i, j, :)

    total_precip_M[i, j]   = mean(d)
    total_precip_VAR[i, j] = std(d)
   
    d_wrap = reshape(d, 12, :)
    total_precip_MM[i, j, :]   = mean( d_wrap, dims=2 )[:, 1]
    total_precip_MVAR[i, j, :] = std( d_wrap, dims=2 )[:, 1]

end

for j=1:Ny

    d = mean(view(total_precip, :, j, :), dims=1)[1, :]

    total_precip_ZM[j]   = mean(d)
    total_precip_ZVAR[j] = std(d)
   
    d_wrap = reshape(d, 12, :)
    total_precip_ZMM[j, :]   = mean( d_wrap, dims=2 )[:, 1]
    total_precip_ZMVAR[j, :] = std(  d_wrap, dims=2 )[:, 1]

end




Dataset(output_file, "c") do ds

    defDim(ds, "months", 12)
    defDim(ds, "time", Inf)
    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    
    for (varname, vardata, vardim, attrib) in [
        ("total_precip_M",     total_precip_M,     ("Nx", "Ny",), Dict()),
        ("total_precip_VAR",   total_precip_VAR,   ("Nx", "Ny",), Dict()),
        ("total_precip_MM",    total_precip_MM,    ("Nx", "Ny", "months"), Dict()),
        ("total_precip_MVAR",  total_precip_MVAR,  ("Nx", "Ny", "months"), Dict()),
        ("total_precip_ZM",    total_precip_ZM,    ("Ny",), Dict()),
        ("total_precip_ZVAR",  total_precip_ZVAR,  ("Ny",), Dict()),
        ("total_precip_ZMM",   total_precip_ZMM,   ("Ny", "months"), Dict()),
        ("total_precip_ZMVAR", total_precip_ZMVAR, ("Ny", "months"), Dict()),
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
