using Statistics
using NCDatasets

using ArgParse
using JSON
using Formatting

include("LinearRegression.jl")
include("nanop.jl")
include("CESMReader2.jl")

using .CESMReader2

correlation = (x1, x2) -> x1' * x2 / (sum(x1.^2)*sum(x2.^2)).^0.5

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--data-file-prefix"
            help = "Data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
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

    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

output_file = parsed["output-file"]

filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))

# Determine the shape of the variable

CESMReader2.iterFilenames(filename_format, (parsed["beg-year"], parsed["end-year"])) do filename, y, m

    Dataset(filename, "r") do ds
        v = ds[parsed["varname"]]
        global var_dins = dimnames(v)
        global var_dims = [ ds.dim[var_dins[i]] for i=1:length(var_dins) ]


        if var_dins[end] != "time" 
            throw(ErrorException("The last dimension is not time"))
        end

        if var_dims[end] != 1
            throw(ErrorException("The last dimension time has more than 1 record"))
        end
        
        global spatial_dins = var_dins[1:end-1]
        global spatial_dims = var_dims[1:end-1]
        global spatial_cols = [Colon() for i=1:length(spatial_dims)]

        println("var_dins: ", string(var_dins))
        println("var_dims: ", string(var_dims))

    end

    return false
end


# M = monthly
# S = seasonal
# A = annual
data_MM    = zeros(Float64, spatial_dims..., 12)
data_MMSQR = zeros(Float64, spatial_dims..., 12)


tmp_AM     = zeros(Float64, spatial_dims...)
data_AM    = zeros(Float64, spatial_dims...)
data_AMSQR = zeros(Float64, spatial_dims...)

years   = parsed["end-year"] - parsed["beg-year"] + 1
months  = years * 12


CESMReader2.iterFilenames(filename_format, (parsed["beg-year"], parsed["end-year"])) do filename, y, m
    println("Loading $filename")
    Dataset(filename, "r") do ds

        global data_MM, data_MMSQR, tmp_AM, data_AM, data_AMSQR

        v = ds[parsed["varname"]][spatial_cols..., 1]

        data_MM[spatial_cols..., m] .+= v
        data_MMSQR[spatial_cols..., m] .+= v.^2

        tmp_AM .+= v
        if m == 12
            @. tmp_AM /= 12.0
            @. data_AM += tmp_AM
            @. data_AMSQR += tmp_AM^2
            @. tmp_AM = 0.0
        end
    end
end

data_MM ./= years
data_MMSQR ./= years
data_MMVAR = abs.(data_MMSQR - data_MM.^2)
data_MMSTD = data_MMVAR.^0.5

data_AM ./= years
data_AMSQR ./= years
data_AMVAR = abs.(data_AMSQR - data_AM.^2)
data_AMSTD = data_AMVAR.^0.5

Dataset(output_file, "c") do ds

    defDim(ds, "months", 12)

    for i=1:length(var_dins)
        defDim(ds, var_dins[i], var_dims[i])
    end

    datas =  convert(Array{Any}, [

        (format("{:s}_MM",    parsed["varname"]),       data_MM,    (spatial_dins..., "months"), Dict()),
        (format("{:s}_MMVAR", parsed["varname"]),       data_MMVAR, (spatial_dins..., "months"), Dict()),
        (format("{:s}_MMSTD", parsed["varname"]),       data_MMSTD, (spatial_dins..., "months"), Dict()),

        (format("{:s}_AM",    parsed["varname"]),       data_AM,    (spatial_dins...,), Dict()),
        (format("{:s}_AMVAR", parsed["varname"]),       data_AMVAR, (spatial_dins...,), Dict()),
        (format("{:s}_AMSTD", parsed["varname"]),       data_AMSTD, (spatial_dins...,), Dict()),

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
        var[:] = vardata
    end

end
