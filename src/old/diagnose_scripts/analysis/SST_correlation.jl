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
 
        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true
      
        "--SST"
            help = "Variable name of SST."
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

Dataset(parsed["data-file"], "r") do ds

    dims = size(ds[parsed["SST"]])

    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12


    if length(dims) == 3 # 2D + time
        rng = (:,:,beg_t:end_t) 
    elseif length(dims) == 4 # 2D + time
        rng = (:,:,1,beg_t:end_t) 
    else
        ErrorException("Unknown dimension") |> throw
    end

    global SST  = replace(ds[parsed["SST"]][rng...], missing=>NaN)

    global (Nx, Ny, Nt) = size(SST)
    
    if mod(Nt, 12) != 0

        SST = SST[:, :, 1:12*floor(Integer, Nt/12.0)]
        (Nx, Ny, Nt) = size(SST)
        
        #ErrorException("Time record is not multiple of 12") |> throw
    end
    
    global nyears = Int64(Nt / 12)
end

Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
end

# MM   = Monthly Mean
# A    = Anomaly
# YYC  = Year-to-Year Correlation

SSTMM   = zeros(Float64, size(SST)[1:2]..., 12)
SSTA    = zeros(Float64, size(SST)...)
SSTAYYC = zeros(Float64, size(SST)[1:2]..., 12)
SSTAVAR = zeros(Float64, size(SST)[1:2]..., 12)


N = size(SST)[3]
x = collect(Float64, 1:N)
for i=1:Nx, j=1:Ny

    d = detrend(x, view(SST, i, j, :))

    if mask[i, j] != 0
        SSTMM[i, j, :]  .= NaN
        SSTA[i, j, :]   .= NaN
        SSTAYYC[i, j, :] .= NaN
        continue
    end

        
    
    SSTMM[i, j, :] = mean( reshape(d, 12, :), dims=2 )[:, 1]
    SSTA[i, j, :]  = d - repeat( SSTMM[i, j, :], outer=nyears)
    
    for m = 1:12
        d_yy = view(SSTA, i, j, m:12:(m+nyears*12-1))
        SSTAYYC[i, j, m] = correlation(d_yy[1:end-1], d_yy[2:end])
        SSTAVAR[i, j, m] = std(d_yy)
    end
 
end

Dataset(parsed["data-file"], "a") do ds
    if ! haskey(ds.dim, "months")
        defDim(ds, "months", 12)
    end
end

Dataset(parsed["data-file"], "a") do ds
    for (varname, vardata, vardim, attrib) in [
        ("SSTMM",  SSTMM, ("Nx", "Ny", "months"), Dict()),
        ("SSTA",    SSTA, ("Nx", "Ny", "time"),   Dict()),
        ("SSTAYYC",  SSTAYYC, ("Nx", "Ny", "months"), Dict()),
        ("SSTAVAR",  SSTAVAR, ("Nx", "Ny", "months"), Dict()),
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
