using Statistics
using NCDatasets

using ArgParse
using JSON
using Formatting

include("LinearRegression.jl")
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
            help = "Output atm temperature file."
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

let

    if parsed["data-file-timestamp-form"] == "YEAR"
        filename_format = format("{:s}{{:04d}}.nc", joinpath(parsed["data-file-prefix"]))
        form = :YEAR
    elseif parsed["data-file-timestamp-form"] == "YEAR_MONTH"
        filename_format = format("{:s}{{:04d}}-{{:02d}}.nc", joinpath(parsed["data-file-prefix"]))
        form = :YEAR_MONTH
    end
   
    fh = FileHandler(filename_format=filename_format, form=form)

    global TREFHT = getData(fh, "TREFHT", (parsed["beg-year"], parsed["end-year"]), (:, :))
    global (Nx, Ny, Nt) = size(TREFHT)
    global nyears = Int64(Nt / 12)
    
    if mod(Nt, 12) != 0
        ErrorException("Time record is not multiple of 12") |> throw
    end

end

Dataset(parsed["domain-file"], "r") do ds
    global mask = replace(ds["mask"], missing=>NaN)
    global lat  = replace(ds["yc"], missing=>NaN)


    global lnd_mask = mask .== 1
    global ocn_mask = mask .!= 1
    
    global w_GLB = cos.(lat * π/180.0)
    global w_LND = w_GLB .* lnd_mask
    global w_OCN = w_GLB .* ocn_mask

    global sum_w_GLB = sum(w_GLB)
    global sum_w_LND = sum(w_LND)
    global sum_w_OCN = sum(w_OCN)
end


TREFHTA    = zeros(Float64, Nx, Ny, Nt)
TREFHTAVAR = zeros(Float64, Nx, Ny, 12)
TREFHTMM   = zeros(Float64, Nx, Ny, 12)
x = collect(Float64, 1:Nt)
for i=1:Nx, j=1:Ny

    d = view(TREFHT, i, j, :)
 
    TREFHTMM[i, j, :] = mean( reshape(d, 12, :), dims=2 )[:, 1]
    TREFHTA[i, j, :]  = d - repeat( TREFHTMM[i, j, :], outer=nyears)
    
    for m = 1:12
        d_yy = view(TREFHTA, i, j, m:12:(m+nyears*12-1))
        TREFHTAVAR[i, j, m] = std(d_yy)
    end
 
end


TREFHT_GLB = zeros(Float64, Nt)
TREFHT_LND = zeros(Float64, Nt)
TREFHT_OCN = zeros(Float64, Nt)
for t=1:Nt

    T = view(TREFHT, :, :, t)

    TREFHT_GLB[t] = sum(w_GLB .*  T) / sum_w_GLB
    TREFHT_LND[t] = sum(w_LND .*  T) / sum_w_LND
    TREFHT_OCN[t] = sum(w_OCN .*  T) / sum_w_OCN
 
end


# Meridional distribution

TREFHT_ZM     = zeros(Float64, Ny)
TREFHT_ZVAR   = zeros(Float64, Ny)

TREFHT_ZMM    = zeros(Float64, Ny, 12)
TREFHT_ZMVAR  = zeros(Float64, Ny, 12)

for j=1:Ny

    d = mean(view(TREFHT, :, j, :), dims=1)[1, :]

    TREFHT_ZM[j]   = mean(d)
    TREFHT_ZVAR[j] = std(d)
   
    d_wrap = reshape(d, 12, :)
    TREFHT_ZMM[j, :]   = mean( d_wrap, dims=2 )[:, 1]
    TREFHT_ZMVAR[j, :] = std(  d_wrap, dims=2 )[:, 1]

end


Dataset(output_file, "c") do ds

    defDim(ds, "months", 12)
    defDim(ds, "time", Inf)
    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)

    ds.attrib["TREFHT_GLB_mean"] = Float64(mean(TREFHT_GLB))
    ds.attrib["TREFHT_OCN_mean"] = Float64(mean(TREFHT_OCN))
    ds.attrib["TREFHT_LND_mean"] = Float64(mean(TREFHT_LND))
    
    for (varname, vardata, vardim, attrib) in [
        ("TREFHTA",    TREFHTA,    ("Nx", "Ny", "time"), Dict()),
        ("TREFHTMM",   TREFHTMM,   ("Nx", "Ny", "months"), Dict()),
        ("TREFHTAVAR", TREFHTAVAR, ("Nx", "Ny", "months"), Dict()),
        ("TREFHT_GLB", TREFHT_GLB,   ("time",), Dict()),
        ("TREFHT_LND", TREFHT_LND,   ("time",), Dict()),
        ("TREFHT_OCN", TREFHT_OCN,   ("time",), Dict()),
        ("TREFHT_ZM",    TREFHT_ZM,    ("Ny",), Dict()),
        ("TREFHT_ZVAR",  TREFHT_ZVAR,  ("Ny",), Dict()),
        ("TREFHT_ZMM",   TREFHT_ZMM,   ("Ny", "months"), Dict()),
        ("TREFHT_ZMVAR", TREFHT_ZMVAR, ("Ny", "months"), Dict()),
    ]

        println("Doing var: ", varname)

        var = defVar(ds, varname, Float64, vardim)
        var.attrib["_FillValue"] = 1e20

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
