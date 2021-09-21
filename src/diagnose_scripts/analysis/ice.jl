using Statistics
using NCDatasets

using ArgParse
using JSON

include("LinearRegression.jl")
include("constants.jl")

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

    global hi    = replace(ds["hi"][rng...], missing=>NaN)
    global aice  = replace(ds["aice"][rng...], missing=>NaN) / 100.0

    global (Nx, Ny, Nt) = size(hi)
    
    if mod(Nt, 12) != 0
        ErrorException("Time record is not multiple of 12") |> throw
    end
    
    global nyears = Int64(Nt / 12)
end

Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
    global area = replace(ds["area"], missing=>NaN)
end

mask_idx = (mask .== 0.0)
total_area = sum(area)

total_ice_volume = zeros(Float64, Nt)
total_ice_area   = zeros(Float64, Nt)

hi_trend         = zeros(Float64, Nx, Ny)
aice_trend       = zeros(Float64, Nx, Ny)

hi_trend_MA         = zeros(Float64, Nx, Ny, 12)
aice_trend_MA       = zeros(Float64, Nx, Ny, 12)

hi_MA            = zeros(Float64, Nx, Ny, 12)
aice_MA          = zeros(Float64, Nx, Ny, 12)

for var in [total_ice_volume, total_ice_area, hi_trend, aice_trend, hi_trend_MA, aice_trend_MA, hi_MA, aice_MA]
    var .= NaN
end

println("Total area: ", total_area)

# total ice volume and area
for i = 1:Nt
    tmp = area .* view(hi, :, :, i)
    total_ice_volume[i] = sum(tmp[mask_idx])
end
total_ice_volume .*= 4.0 * π * Re^2.0 / total_area

for i = 1:Nt
    tmp = area .* view(aice, :, :, i)
    total_ice_area[i] = sum(tmp[mask_idx])
end
total_ice_area /= 4.0 * π 



# trend

x  = collect(Float64, 1:Nt)
xx = collect(Float64, 1:nyears)

for (var,  trend,      trend_MA,      MA      ) in [
    (hi,   hi_trend,   hi_trend_MA,   hi_MA   ),
    (aice, aice_trend, aice_trend_MA, aice_MA )
]
    for i=1:Nx, j=1:Ny

        d = view(var, i, j, :)

        if mask[i, j] != 0
            continue
        end

        trend[i, j] = LinearRegression(x,d)[2] * 12   # yearly trend

        d_month = reshape(d, 12, :)
        MA[i, j, :] = mean( d_month, dims=2 )[:, 1]

        for m = 1:12
            trend_MA[i, j, m] = LinearRegression(xx, d_month[m, :])[2]
        end
     
    end
end


Dataset(output_file, "c") do ds

    defDim(ds, "months", 12)
    defDim(ds, "time", Inf)
    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    
    for (varname, vardata, vardim, attrib) in [
        ("total_ice_volume", total_ice_volume, ("time", ),             Dict()),
        ("total_ice_area",   total_ice_area,   ("time", ),             Dict()),
        ("hi_trend",         hi_trend,         ("Nx", "Ny"),           Dict()),
        ("hi_trend_MA",      hi_trend_MA,      ("Nx", "Ny", "months"), Dict()),
        ("hi_MA",            hi_MA,            ("Nx", "Ny", "months"), Dict()),
        ("aice_trend",       aice_trend,       ("Nx", "Ny"),           Dict()),
        ("aice_trend_MA",    aice_trend_MA,    ("Nx", "Ny", "months"), Dict()),
        ("aice_MA",          aice_MA,          ("Nx", "Ny", "months"), Dict()),
    ]

        var = defVar(ds, varname, Float64, vardim)
        var.attrib["_FillValue"] = 1e20
        
        for (k, v) in attrib
            var.attrib[k] = v
        end

        rng = []
        for i in 1:length(vardim)
            push!(rng, 1:size(vardata)[i])
        end
        var[rng...] = vardata

    end
end
