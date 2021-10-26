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
 
        "--SST-varname"
            help = "Variable name of SST"
            arg_type = String
            default = "SST"

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

    # Reference: https://www.esrl.noaa.gov/psd/enso/mei/
    # EOF of 30°S-30°N and 100°E-70°W
    global EOF_idx  = (sparsity_mask .== 1) .& (mask .== 0) .& ( -30.0 .<= lat .<= 30.0 ) .& ( 100.0 .<= lon .<= 290.0 )

    # Niño 3.4 (5N-5S, 170W-120W): 
    global EN34_idx = (sparsity_mask .== 1) .& (mask .== 0) .& ( -5.0 .<= lat .<= 5.0 ) .& ( 190.0 .<= lon .<= 240.0 )


    global area_EN34 = area[EN34_idx]
    global sum_area_EN34 = sum(area_EN34)


    # construct mapping of PCA
#    grid_numbering = reshape( collect(1:length(mask)), size(mask)... )
#    global EOF_mapping = grid_numbering[EOF_idx]  # The i-th reduced grid idx onto the original ?-th grid
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
 
    global SST = getData(fh, "SST", (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    global Nt = end_t - beg_t + 1
end


#EOF_pts = sum(EOF_idx)
#EOF_input = zeros(Float64, EOF_pts, Nt)
EN34 = zeros(Float64, Nt)

for t = 1:Nt
    _SST = view(SST, :, :, t)
#    EOF_input[:, t] = _SST[EOF_idx] 
    EN34[t] = sum(_SST[EN34_idx] .* area_EN34) / sum_area_EN34
end

t_vec = collect(eltype(EN34), 1:Nt)
EN34 = detrend(t_vec, EN34, order=2)
#for i=1:EOF_pts
#    EOF_input[i, :] = detrend(t_vec, view(EOF_input, i, :), order=2)
#end

# remove seasonality
rmSeasonality!(EN34; period=12)
#for i=1:EOF_pts
#    vw = view(EOF_input, i, :)
#    rmSeasonality!(vw; period=12)
#end

# Doing PCAs
#modes = 2

#println("Solving for PCA...")
#eigen_vectors = PCA.findPCAs(EOF_input, num=modes)
#println("done.")

#PCAs = zeros(Float64, Nx*Ny, modes)
#PCAs .= NaN

#for i = 1:EOF_pts
#    PCAs[EOF_mapping[i], :] = eigen_vectors[i, :]
#end
modes = 4

PCAs, PCAs_ts = PCA.findPCAs(SST, EOF_idx; modes=modes)

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)
    defDim(ds, "modes", modes)


    for (varname, vardata, vardim, attrib) in [
        ("PCAs",  reshape(PCAs, Nx, Ny, modes), ("Nx", "Ny", "modes",), Dict()),
        ("EN34",  EN34, ("time",), Dict()),
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







