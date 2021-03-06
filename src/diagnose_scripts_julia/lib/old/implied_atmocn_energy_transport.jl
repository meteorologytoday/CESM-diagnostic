using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON

include("constants.jl")
include("CESMReader.jl")

using .CESMReader

function mreplace(x)
    return replace(x, missing=>NaN)
end

function integrate(x, dydx)
    y = copy(dydx) * 0.0

    for i = 2:length(x)
        y[i] = y[i-1] + (dydx[i-1] + dydx[i]) * (x[i] - x[i-1]) / 2.0
    end

    return y
end

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

        "--output-file"
            help = "Output file."
            arg_type = String
            required = true

        "--domain-file"
            help = "Domain file."
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

 
Dataset(parsed["domain-file"], "r") do ds
    global mask = ds["mask"][:] |> mreplace
    global lat = ds["yc"][1, :] |> mreplace

    global lat_weight = Re * cos.(deg2rad.(lat)) * 2π 
    global y          = Re * deg2rad.(lat)

    mask[mask.!=0] .= 1
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
 
    FSNT, FLNT, FSNS, FLNS, SHFLX, LHFLX = getData(fh, ["FSNT", "FLNT", "FSNS", "FLNS", "SHFLX", "LHFLX"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    global FFLX_TOA = ( - mean(FSNT, dims=(1, ))  + mean(FLNT,  dims=(1, )) )[1, :, :]
    global FFLX_SFC = ( - mean(FSNS, dims=(1, ))  + mean(FLNS,  dims=(1, )) )[1, :, :]
    global HFLX_SFC = (   mean(SHFLX, dims=(1, )) + mean(LHFLX, dims=(1, )) )[1, :, :]

    global (Ny, Nt) = size(FFLX_TOA)

    if mod(Nt, 12) != 0
        throw(ErrorException("Time should be a multiple of 12."))
    end

    global nyears = Int64(Nt / 12)
    println(format("We got {:d} years of data.", nyears))
end


IAET       = zeros(Float64, Ny, Nt)
OAET       = zeros(Float64, Ny, Nt)
ATM_EFLX_CONV  = zeros(Float64, Ny, Nt)
OCN_EFLX_CONV  = zeros(Float64, Ny, Nt)

IAET_AM    = zeros(Float64, Ny, nyears)
OAET_AM    = zeros(Float64, Ny, nyears)

for t = 1:Nt

    FFLX_TOA[:, t] .*= lat_weight 
    FFLX_SFC[:, t] .*= lat_weight
    HFLX_SFC[:, t] .*= lat_weight
    ATM_EFLX_CONV[:, t] = - ( FFLX_TOA[:, t] - FFLX_SFC[:, t] - HFLX_SFC[:, t] )
    OCN_EFLX_CONV[:, t] = - ( - FFLX_SFC[:, t] - HFLX_SFC[:, t] )

    IAET[:, t] = integrate(y, ATM_EFLX_CONV[:, t])
    IOET[:, t] = integrate(y, OCN_EFLX_CONV[:, t])

end

for j = 1:Ny, t = 1:nyears
    IAET_AM[j, t] = mean(IAET[j, (t-1)*12+1:t*12])
    OAET_AM[j, t] = mean(OAET[j, (t-1)*12+1:t*12])
end


Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("FFLX_TOA",  FFLX_TOA,  ("Ny", "time"), Dict()),
        ("FFLX_SFC",  FFLX_SFC,  ("Ny", "time"), Dict()),
        ("HFLX_SFC",  HFLX_SFC,  ("Ny", "time"), Dict()),
        ("ATM_EFLX_CONV", ATM_EFLX_CONV, ("Ny", "time"), Dict()),
        ("OCN_EFLX_CONV", OCN_EFLX_CONV, ("Ny", "time"), Dict()),
        ("IAET",      IAET,      ("Ny", "time"), Dict()),
        ("OAET",      OAET,      ("Ny", "time"), Dict()),
        ("FFLX_TOA_mean",  mean(FFLX_TOA, dims=(2,))[:, 1],  ("Ny", ), Dict()),
        ("FFLX_SFC_mean",  mean(FFLX_SFC, dims=(2,))[:, 1],  ("Ny", ), Dict()),
        ("HFLX_SFC_mean",  mean(HFLX_SFC, dims=(2,))[:, 1],  ("Ny", ), Dict()),
        ("EFLX_CONV_mean", mean(EFLX_CONV, dims=(2,))[:, 1], ("Ny", ), Dict()),
        ("IAET_AM",        mean(IAET_AM, dims=(2,))[:, 1],   ("Ny", ), Dict()),
        ("IAET_AMSTD",     std( IAET_AM, dims=(2,))[:, 1],   ("Ny", ), Dict()),
        ("OAET_AM",        mean(OAET_AM, dims=(2,))[:, 1],   ("Ny", ), Dict()),
        ("OAET_AMSTD",     std( OAET_AM, dims=(2,))[:, 1],   ("Ny", ), Dict()),

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

















