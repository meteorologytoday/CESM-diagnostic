using Statistics
using NCDatasets

using ArgParse
using JSON
using Formatting

include("LinearRegression.jl")
include("nanop.jl")
include("CESMReader.jl")

using .CESMReader

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file-prefix"
            help = "Data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
            arg_type = String
            required = true
 
        "--data-file-timestamp-form"
            help = "Data filename timestamp form. Either `YEAR` or `YEAR_MONTH`."
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

        "--dims"
            help = "The form of dimensions. Now can be `XYZT`, `XYT`, `YZT`"        
            arg_type = String
            required = true

    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

output_file = parsed["output-file"]

if parsed["data-file-timestamp-form"] == "YEAR"
    filename_format = format("{:s}{{:04d}}.nc", joinpath(parsed["data-file-prefix"]))
    form = :YEAR
elseif parsed["data-file-timestamp-form"] == "YEAR_MONTH"
    filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))
    form = :YEAR_MONTH
end
    


Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
end

if ! ( parsed["dims"] in ["XYZT", "XYT", "YZT", "YZ"] )
    ErrorException("Unknown dimension: " * parsed["dims"]) |> throw
end

# Creating preknowledge of dimensions
Dataset(format(filename_format, parsed["beg-year"], 1), "r") do ds

    var = ds[parsed["varname"]]
    dims = size(var)

    global beg_t = (parsed["beg-year"] - 1) * 12 + 1
    global end_t = (parsed["end-year"] - 1) * 12 + 12

    if parsed["dims"] == "XYZT"
        global (Nx, Ny, Nz, _ ) = size(var)
    elseif parsed["dims"] == "XYT"
        global (Nx, Ny, _ ) = size(var)
        Nz = 1
    elseif parsed["dims"] == "YZT"
        global (Ny, Nz, _ ) = size(var)
        Nx = 1
    elseif parsed["dims"] == "YZ"
        global (Ny, Nz ) = size(var)
        Nx = 1
    end

    global Nt = end_t - beg_t + 1
    
    if mod(Nt, 12) != 0
        ErrorException("Time record is not multiple of 12") |> throw
    end
    
    global Na = Int64(Nt / 12)
    global Ns = Int64(Nt / 3)
end


months  = collect(Float64, 1:Nt)
years   = collect(Float64, 1:Na)

fh = FileHandler(filename_format=filename_format, form=form)


if parsed["dims"] == "XYZT"

    spatial_rng = (:, :, :)
    global data = reshape( getData(fh, parsed["varname"], (parsed["beg-year"], parsed["end-year"]), spatial_rng), Nx, Ny, Nz, Nt)
        
elseif  parsed["dims"] == "XYT"

    spatial_rng = (:, :)
    global data = reshape( getData(fh, parsed["varname"], (parsed["beg-year"], parsed["end-year"]), spatial_rng), Nx, Ny, Nz, Nt)

end


data_MM = nanmean( data, dims=(1,) )

data_AM = zeros(Float64, 1, Ny, Nz, Na)

for a=1:Na
    data_AM[:, :, :, a] = mean( view(data_MM, :, :, :, ((a-1)*12+1):(a*12) ), dims=4 )[:, :, :, 1]
end


Dataset(output_file, "c") do ds

    defDim(ds, "years",  Na)
    defDim(ds, "months", Nt)
    defDim(ds, "Nx", 1)
    defDim(ds, "Ny", Ny)
    defDim(ds, "Nz", Nz)

    datas =  convert(Array{Any}, [

        (format("{:s}_MM",    parsed["varname"]),       data_MM,    ("Nx", "Ny", "Nz", "months"), Dict()),
        (format("{:s}_AM",    parsed["varname"]),       data_AM,    ("Nx", "Ny", "Nz", "years"), Dict()),

    ])

    if  parsed["dims"] in [ "XYT", "XYZT" ]
        push!(datas, ("mask",  mask,    ("Nx", "Ny"),   Dict()))
    end
    
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
