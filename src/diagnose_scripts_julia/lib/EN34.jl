using Statistics
using NCDatasets

using ArgParse
using JSON

include("nanop.jl")
include("PCA.jl")

using .PCA


function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file"
            help = "Ocean SSTA data file. New variable will be appended."
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

        "--sparsity"
            help = "Because solving PCA matrix is time consuming. This parameter let user to use coarse data to derive PCA. Sparseity `n` means to skip every `n` other grid point in lon / lat. So sparsity 0 (default) means do not skip any data point. Sparsity 1 means means data density will drop to 1/4 of the original (1/2 * 1/2)."
            arg_type = Int64
            default = 0
      
    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

sparsity = parsed["sparsity"]
inc = sparsity + 1

Dataset(parsed["domain-file"], "r") do ds

    global lon = replace(ds["xc"][:, 1], missing=>NaN)
    global lat = replace(ds["yc"][1, :], missing=>NaN)

    global llon = replace(ds["xc"][:], missing=>NaN)
    global llat = replace(ds["yc"][:], missing=>NaN)


    global mask = replace(ds["mask"][:], missing=>NaN)

    global Nx = length(lon)
    global Ny = length(lat)

    global valid_grids = []


    # Reference: https://www.esrl.noaa.gov/psd/enso/mei/
    # EOF of 30°S-30°N and 100°E-70°W

    global s_j = 1
    global n_j = 1
    global w_i = 1
    global e_i = 1

    for j = 1:Ny
        if - 30.0 <= lat[j]
            global s_j = j
            break
        end
    end
    for j = Ny:-1:s_j
        if 30.0 >= lat[j]
            global n_j = j
            break
        end
    end

    for i = 1:Nx
        if  100.0 <= lon[i]
            global w_i = i
            break
        end
    end
    for i = w_i+1:Nx
        if  290.0 <= lon[i]
            global e_i = i-1
            break
        end
    end


    for i = w_i:inc:e_i, j = s_j:inc:n_j
        if mask[i, j] == 0.0
            push!(valid_grids, (i, j))
        end
    end

end


Dataset(parsed["data-file"], "r") do ds

    global SSTA  = replace(ds["T_ML_MA"][:, :, 1, :], missing=>NaN)
    global months  = ds.dim["time"]

    global EOF_input = zeros(Float64, length(valid_grids), months)
    for i = 1:length(valid_grids)
        EOF_input[i, :] = SSTA[valid_grids[i][1], valid_grids[i][2], :]
    end

end

# El nino 3.4
# 170W - 120W  => [190 - 240]
# 5S - 5N

EN34idx = (abs.(llat) .<= 5) .& (llon .>= 190) .& (llon .<= 240)

EN34 = zeros(Float64, months)
for i = 1:months

    SSTA_slice = view(SSTA, :, :, i)
    EN34[i] = nanmean(SSTA_slice[EN34idx])

end


# Doing PCAs
modes = 2

println("Solving for PCA...")
eigen_vectors = PCA.findPCAs(EOF_input, num=modes)
println("done.")

PCAs = zeros(Float64, Nx, Ny, modes)
PCAs .= NaN

for i = 1:length(valid_grids)
    PCAs[valid_grids[i][1], valid_grids[i][2], :] = eigen_vectors[i, :]
end


ENSO = zeros(Float64, months)

ENSO_mode = view(PCAs, :, :, 1)
for i = 1:length(ENSO)
    ENSO[i] = nansum(ENSO_mode .* SSTA[:, :, i])
end

# Map grid back because of sparsity
if sparsity > 0
    for m = 1:modes, i = w_i:inc:e_i, j=s_j:inc:n_j
        if mask[i, j] == 0.0
            PCAs[i:min(e_i, i+sparsity), j:min(n_j, j+sparsity), m] .= PCAs[i, j, m]
        end
    end
end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)
    defDim(ds, "modes", modes)


    for (varname, vardata, vardim, attrib) in [
        ("PCAs",  PCAs, ("Nx", "Ny", "modes",), Dict()),
        ("EN34",  EN34, ("time",), Dict()),
        ("ENSO",  ENSO, ("time",), Dict()),
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






