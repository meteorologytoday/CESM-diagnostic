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

        "--output-file"
            help = "Output file."
            arg_type = String
            required = true
 
        "--data-file"
            help = "Ocean SSTA data file."
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

Dataset(parsed["domain-file"], "r") do ds
    global lon = replace(ds["xc"][:, 1], missing=>NaN)
    global lat = replace(ds["yc"][1, :], missing=>NaN)
    global mask = replace(ds["mask"][:], missing=>NaN)

    global Nx = length(lon)
    global Ny = length(lat)

    global valid_grids = []

    for i = 1:Nx, j = 1:Ny
        if mask[i, j] == 0.0 && ( 115.0 <= lon[i] <= 255.0 ) && ( 20.0 <= lat[j] <= 65.0 )
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

modes = 2

println("Solving for PCA...")
eigen_vectors = PCA.findPCAs(EOF_input, num=modes)
println("done.")

PCAs = zeros(Float64, Nx, Ny, modes)
PCAs .= NaN

for i = 1:length(valid_grids)
    PCAs[valid_grids[i][1], valid_grids[i][2], :] = eigen_vectors[i, :]
end


PDO = zeros(Float64, months)

PDO_mode = view(PCAs, :, :, 1)
for i = 1:length(PDO)
    PDO[i] = nansum(PDO_mode .* SSTA[:, :, i])
end


Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)
    defDim(ds, "modes", modes)


    for (varname, vardata, vardim, attrib) in [
        ("PCAs",  PCAs, ("Nx", "Ny", "modes",), Dict()),
        ("PDO",   PDO, ("time",), Dict()),
    ]

        var = defVar(ds, varname, Float64, vardim)
        var.attrib["_FillValue"] = 1e20
        
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






