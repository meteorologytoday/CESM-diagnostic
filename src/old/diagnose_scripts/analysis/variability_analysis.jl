using Statistics
using NCDatasets
using Formatting

using ArgParse
using JSON

include("LinearRegression.jl")
include("nanop.jl")


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

        "--varname"
            help = "Variable name. If it is 2D then it should be (lon, lat, time), if it is 3D then it should be (lon, lat, lev/depth, time)"
            arg_type = String
            required = true
       
        "--detrend"
            help = "Whether to detrend the data or not."
            action = :store_true 

    
    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

output_file = parsed["output-file"]

Dataset(parsed["data-file"], "r") do ds

    dims = size(ds[parsed["varname"]])

    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12


    if length(dims) == 3 # 2D + time
        rng = (:,:,beg_t:end_t) 
        z_exists = false
    elseif length(dims) == 4 # 3D + time
        rng = (:,:,:,beg_t:end_t) 
        z_exists = true
    else
        ErrorException("Unknown dimension") |> throw
    end

    global data  = replace(ds[parsed["varname"]][rng...], missing=>NaN)

    if z_exists
        global (Nx, Ny, Nz, Nt) = size(data)
    else
        global (Nx, Ny, Nt) = size(data)
        Nz = 1
        data = reshape(data, Nx, Ny, Nz, Nt)
    end 

    
    if mod(Nt, 12) != 0
        ErrorException("Time record is not multiple of 12") |> throw
    end
    
    global nyears = Int64(Nt / 12)
end

Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
end

# MM   = Monthly Mean
# A    = Anomaly
# YYC  = Year-to-Year Correlation

data = nanmean(data, dims=(1,))[1, :, :, :]

data_MM    = zeros(Float64, Ny, Nz, 12)
data_MA    = zeros(Float64, Ny, Nz, Nt)
data_MAVAR = zeros(Float64, Ny, Nz, 12)

x = collect(Float64, 1:Nt)
for j=1:Ny, k=1:Nz


    d = view(data, j, k, :)
    if parsed["detrend"]
        d = detrend(x, d)
    end

    data_MM[j, k, :] = mean( reshape(d, 12, :), dims=2 )[:, 1]

#    println("size: ", size(data_MA))

    data_MA[j, k, :] = d - repeat( data_MM[j, k, :], outer=nyears)
    
    for m = 1:12
        d_yy = view(data_MA, j, k, m:12:(m+nyears*12-1))
        data_MAVAR[j, k, m] = std(d_yy)
    end
 
end



Dataset(output_file, "c") do ds

    defDim(ds, "months", 12)
    defDim(ds, "time", Inf)
    defDim(ds, "Ny", Ny)
    defDim(ds, "Nz", Nz)
    
    for (varname, vardata, vardim, attrib) in [
        (format("{:s}_MM",    parsed["varname"]), data_MM,    ("Ny", "Nz", "months"), Dict()),
        (format("{:s}_MA",    parsed["varname"]), data_MA,    ("Ny", "Nz", "time"),   Dict()),
        (format("{:s}_MAVAR", parsed["varname"]), data_MAVAR, ("Ny", "Nz", "months"), Dict()),
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
