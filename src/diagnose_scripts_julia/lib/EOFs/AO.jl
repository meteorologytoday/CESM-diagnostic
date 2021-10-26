include("../constants.jl")
include("../CESMReader.jl")
include("../LinearRegression.jl")
include("../PCA.jl")

using .PCA
using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON
using .CESMReader


function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file-timestamp-form"
            help = "Data filename timestamp form. Either `YEAR` or `YEAR_MONTH`."
            arg_type = String
            required = true
 
        "--dims"
            help = "The form of dimensions. Now can be `XYZT`, `XYT`, `YZT`"        
            arg_type = String
            required = true


        "--data-file-prefix"
            help = "Input data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
            arg_type = String
            required = true
 
        "--output-file"
            help = "Output data filename"
            arg_type = String
            required = true
 
        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true
 
        "--SLP-varname"
            help = "Variable name of sea-level pressure"
            arg_type = String
            default = "PSL"

        "--beg-year"
            help = "Year of begin."
            arg_type = Int64
            required = true

        "--end-year"
            help = "Year of end."
            arg_type = Int64
            required = true

        "--overwrite"
            action = :store_true


        "--sparsity"
            help = "Because solving PCA matrix is time consuming. This parameter let user to use coarse data to derive PCA. Sparseity `n` means to skip every `n-1` other grid point in lon / lat. So sparsity 1 (default) means do not skip any data point. Sparsity 1 means means data density will drop to 1/4 of the original (1/2 * 1/2)."
            arg_type = Int64
            default = 1
 
    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

Dataset(parsed["domain-file"], "r") do ds

    global lon = replace(ds["xc"][:], missing=>NaN)
    global lat = replace(ds["yc"][:], missing=>NaN)
    global mask = replace(ds["mask"][:], missing=>NaN)
    global area = replace(ds["area"][:], missing=>NaN)

    global Nx, Ny = size(lat)

    # sparsity
    global sparsity_mask = copy(mask)
    sparsity_mask .= 0.0

    skip = parsed["sparsity"]

    for i=1:Nx, j=1:Ny
        if i % skip == 0 && j % skip == 0
            sparsity_mask[i, j] = 1.0
        end
    end

    global AO_idx  = (sparsity_mask .== 1) .& ( 20 .<= lat )

end

let
    if parsed["data-file-timestamp-form"] == "YEAR"
        filename_format = format("{:s}{{:04d}}.nc", joinpath(parsed["data-file-prefix"]))
        form = :YEAR
    elseif parsed["data-file-timestamp-form"] == "YEAR_MONTH"
        filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))
        form = :YEAR_MONTH
    end
   
    fh = FileHandler(filename_format=filename_format, form=form)

    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12
 
    global SLP = getData(fh, parsed["SLP-varname"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    global Nt = end_t - beg_t + 1
end

modes = 4

PCAs, PCAs_ts = PCA.findPCAs(SLP, AO_idx; modes=modes)

Dataset(parsed["output-file"], "c") do ds
    
    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)
    defDim(ds, "modes", modes)
    
    for (varname, vardata, vardim, attrib) in [
        ("PCAs",  reshape(PCAs, Nx, Ny, modes), ("Nx", "Ny", "modes",), Dict()),
        ("PCAs_ts",  PCAs_ts, ("modes", "time",), Dict()),
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







