using Statistics
using NCDatasets

using ArgParse
using JSON
using Formatting

include("LinearRegression.jl")
include("nanop.jl")
include("CESMReader.jl")

using .CESMReader

correlation = (x1, x2) -> x1' * x2 / (sum(x1.^2)*sum(x2.^2)).^0.5

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

        "--no-detrend"
            help = "Whether to detrend the data or not."
            action = :store_true

        "--output-monthly-anomalies"
            help = "Whether to output the monthly anomalies for all months."
            action = :store_true 

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
    
    global nyears = Int64(Nt / 12)
    global Ns = Int64(Nt / 3)
    global Na = Int64(Nt / 12)
end

# M = monthly
# S = seasonal
# A = annual

data_MM    = zeros(Float64, Nx, Ny, Nz, 12)
data_MA    = zeros(Float64, Nx, Ny, Nz, Nt)
data_MAVAR = zeros(Float64, Nx, Ny, Nz, 12)
data_MASTD = zeros(Float64, Nx, Ny, Nz, 12)

data_SM    = zeros(Float64, Nx, Ny, Nz, 4)
data_SA    = zeros(Float64, Nx, Ny, Nz, Ns)
data_SAVAR = zeros(Float64, Nx, Ny, Nz, 4)
data_SASTD = zeros(Float64, Nx, Ny, Nz, 4)

data_AM    = zeros(Float64, Nx, Ny, Nz, 1)
data_AA    = zeros(Float64, Nx, Ny, Nz, Na)
data_AAVAR = zeros(Float64, Nx, Ny, Nz, 1)
data_AASTD = zeros(Float64, Nx, Ny, Nz, 1)

data_ZONAL_MM    = zeros(Float64, Ny, Nz, 12)
data_ZONAL_MA    = zeros(Float64, Ny, Nz, Nt)
data_ZONAL_MAVAR = zeros(Float64, Ny, Nz, 12)
data_ZONAL_MASTD = zeros(Float64, Ny, Nz, 12)

data_ZONAL_SM    = zeros(Float64, Ny, Nz, 4)
data_ZONAL_SA    = zeros(Float64, Ny, Nz, Ns)
data_ZONAL_SAVAR = zeros(Float64, Ny, Nz, 4)
data_ZONAL_SASTD = zeros(Float64, Ny, Nz, 4)

data_ZONAL_AM    = zeros(Float64, Ny, Nz, 1)
data_ZONAL_AA    = zeros(Float64, Ny, Nz, Na)
data_ZONAL_AAVAR = zeros(Float64, Ny, Nz, 1)
data_ZONAL_AASTD = zeros(Float64, Ny, Nz, 1)

months  = collect(Float64, 1:Nt)
seasons = collect(Float64, 1:Ns)
years   = collect(Float64, 1:Na)

fh = FileHandler(filename_format=filename_format, form=form)

function doit!(
    t    :: AbstractArray{Float64, 1},
    d     :: AbstractArray{Float64, 1},
    M    :: AbstractArray{Float64},
    A    :: AbstractArray{Float64},
    AVAR :: AbstractArray{Float64},
    ASTD :: AbstractArray{Float64},
    nyears :: Integer,
    period :: Integer,
    idx  :: Tuple, 
)

    if ! parsed["no-detrend"]
        d = detrend(t, d, order=2)
    end
    
    M[idx..., :] = mean( reshape(d, period, :), dims=2 )[:, 1]
    A[idx..., :] = d - repeat( M[idx..., :], outer=nyears)
    
    for m = 1:period
        d_yy = view(A, idx..., m:period:(m+nyears*period-1))
        AVAR[idx..., m] = var(d_yy)
        ASTD[idx..., m] = std(d_yy)
    end

end

if parsed["dims"] == "XYZT"

    for k=1:Nz
        spatial_rng = (:, :, k)
        global data = reshape( getData(fh, parsed["varname"], (parsed["beg-year"], parsed["end-year"]), spatial_rng), Nx, Ny, Nt)
        
        for i=1:Nx, j=1:Ny
            d = view(data, i, j, :)
            doit!(months,           d, data_MM, data_MA, data_MAVAR, data_MASTD, nyears, 12, i, j, k)    
            
            seasonal_d = mean(reshape( circshift(d, -2), 3, :), dims=1)[1, :]
            doit!(seasons, seasonal_d, data_SM, data_SA, data_SAVAR, data_SASTD, nyears,  4, i, j, k)
 
            annual_d = mean(reshape( d, 12, :), dims=1)[1, :]
            doit!(years, annual_d, data_AM, data_AA, data_AAVAR, data_AASTD, nyears,  1, i, j, k)    
        end 
    end

elseif  parsed["dims"] == "XYT"

    spatial_rng = (:, :)
    global data = reshape( getData(fh, parsed["varname"], (parsed["beg-year"], parsed["end-year"]), spatial_rng), Nx, Ny, Nt)
    for i=1:Nx, j=1:Ny

        d = view(data, i, j, :)
        doit!(months,           d, data_MM, data_MA, data_MAVAR, data_MASTD, nyears, 12, (i, j, 1) )
        
        seasonal_d = mean(reshape( circshift(d, -2), 3, :), dims=1)[1, :]
        doit!(seasons, seasonal_d, data_SM, data_SA, data_SAVAR, data_SASTD, nyears,  4, (i, j, 1) )   

        annual_d = mean(reshape( d, 12, :), dims=1)[1, :]
        doit!(years, annual_d, data_AM, data_AA, data_AAVAR, data_AASTD,     nyears,  1, (i, j, 1) )

    end

    # === zonal mean ====
    data_zonal = nanmean( data, dims=(1,) )
    for j=1:Ny        

        monthly_d = view(data_zonal, 1, j, :)
        doit!(months, monthly_d, data_ZONAL_MM, data_ZONAL_MA, data_ZONAL_MAVAR, data_ZONAL_MASTD, nyears, 12, (j, 1))
 
        seasonal_d = mean(reshape( circshift(monthly_d, -2), 3, :), dims=1)[1, :]
        doit!(seasons, seasonal_d, data_ZONAL_SM, data_ZONAL_SA, data_ZONAL_SAVAR, data_ZONAL_SASTD, nyears, 4, (j, 1))
        
        annual_d = mean(reshape( monthly_d, 12, : ), dims=1)[1, :]
        doit!(years,   annual_d, data_ZONAL_AM, data_ZONAL_AA, data_ZONAL_AAVAR, data_ZONAL_AASTD, nyears, 1, (j, 1))
 
    end 

elseif parsed["dims"] in ["YZT", "YZ"]

    spatial_rng = (:, :)
    global data = reshape( getData(fh, parsed["varname"], (parsed["beg-year"], parsed["end-year"]), spatial_rng), Ny, Nz, Nt)
    for j=1:Ny, k=1:Nz
        
        d = view(data, j, k, :)
        doit!(months,           d, data_MM, data_MA, data_MAVAR, data_MASTD, nyears, 12, (1, j, k)    )
        
        seasonal_d = mean(reshape( circshift(d, -2 ), 3, :), dims=1)[1, :]
        doit!(seasons, seasonal_d, data_SM, data_SA, data_SAVAR, data_SASTD, nyears,  4, (1, j, k)    )

        annual_d = mean(reshape( d, 12, :), dims=1)[1, :]
        doit!(years, annual_d, data_AM, data_AA, data_AAVAR, data_AASTD,     nyears,  1, (1, j, k)    )

    end 


    data_ZONAL_MM .= data_MM[1, :, :, :]
    data_ZONAL_MA .= data_MA[1, :, :, :]
    data_ZONAL_MAVAR .= data_MAVAR[1, :, :, :]
    data_ZONAL_MASTD .= data_MASTD[1, :, :, :]

    data_ZONAL_SM .= data_SM[1, :, :, :]
    data_ZONAL_SA .= data_SA[1, :, :, :]
    data_ZONAL_SAVAR .= data_SAVAR[1, :, :, :]
    data_ZONAL_SASTD .= data_SASTD[1, :, :, :]

    data_ZONAL_AM .= data_AM[1, :, :, :]
    data_ZONAL_AA .= data_AA[1, :, :, :]
    data_ZONAL_AAVAR .= data_AAVAR[1, :, :, :]
    data_ZONAL_AASTD .= data_AASTD[1, :, :, :]

end

Dataset(output_file, "c") do ds

    defDim(ds, "months", 12)
    defDim(ds, "seasons", 4)
    defDim(ds, "years", 1)
    defDim(ds, "time", Nt)
    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)
    defDim(ds, "Nz", Nz)

    datas =  convert(Array{Any}, [

        (format("{:s}_MM",    parsed["varname"]),       data_MM,    ("Nx", "Ny", "Nz", "months"), Dict()),
        (format("{:s}_MAVAR", parsed["varname"]),       data_MAVAR, ("Nx", "Ny", "Nz", "months"), Dict()),
        (format("{:s}_MASTD", parsed["varname"]),       data_MASTD, ("Nx", "Ny", "Nz", "months"), Dict()),
        (format("{:s}_ZONAL_MM", parsed["varname"]),    data_ZONAL_MM, ("Ny", "Nz", "months"), Dict()),
        (format("{:s}_ZONAL_MAVAR", parsed["varname"]), data_ZONAL_MAVAR, ("Ny", "Nz", "months"), Dict()),
        (format("{:s}_ZONAL_MASTD", parsed["varname"]), data_ZONAL_MASTD, ("Ny", "Nz", "months"), Dict()),

        (format("{:s}_SM",    parsed["varname"]),       data_SM,    ("Nx", "Ny", "Nz", "seasons"), Dict()),
        (format("{:s}_SAVAR", parsed["varname"]),       data_SAVAR, ("Nx", "Ny", "Nz", "seasons"), Dict()),
        (format("{:s}_SASTD", parsed["varname"]),       data_SASTD, ("Nx", "Ny", "Nz", "seasons"), Dict()),
        (format("{:s}_ZONAL_SM", parsed["varname"]),    data_ZONAL_SM, ("Ny", "Nz", "seasons"), Dict()),
        (format("{:s}_ZONAL_SAVAR", parsed["varname"]), data_ZONAL_SAVAR, ("Ny", "Nz", "seasons"), Dict()),
        (format("{:s}_ZONAL_SASTD", parsed["varname"]), data_ZONAL_SASTD, ("Ny", "Nz", "seasons"), Dict()),

        (format("{:s}_AM",    parsed["varname"]),       data_AM,    ("Nx", "Ny", "Nz", "years"), Dict()),
        (format("{:s}_AAVAR", parsed["varname"]),       data_AAVAR, ("Nx", "Ny", "Nz", "years"), Dict()),
        (format("{:s}_AASTD", parsed["varname"]),       data_AASTD, ("Nx", "Ny", "Nz", "years"), Dict()),
        (format("{:s}_ZONAL_AM", parsed["varname"]),    data_ZONAL_AM, ("Ny", "Nz", "years"), Dict()),
        (format("{:s}_ZONAL_AAVAR", parsed["varname"]), data_ZONAL_AAVAR, ("Ny", "Nz", "years"), Dict()),
        (format("{:s}_ZONAL_AASTD", parsed["varname"]), data_ZONAL_AASTD, ("Ny", "Nz", "years"), Dict()),

    ])

    if parsed["output-monthly-anomalies"]
        push!(datas, (format("{:s}_MA",    parsed["varname"]),       data_MA,    ("Nx", "Ny", "Nz", "time"),   Dict()) )
    end

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
