using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON

include("constants.jl")

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

        "--data-file"
            help = "Atm data file."
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

Dataset(parsed["data-file"], "r") do ds
 
    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12
    rng = (:,:,beg_t:end_t) 
    
    global FFLX_TOA = ( - mean(ds["FSNT"][rng...], dims=(1, ))  + mean(ds["FLNT"][rng...],  dims=(1, )) )[1, :, :]
    global FFLX_SFC = ( - mean(ds["FSNS"][rng...], dims=(1, ))  + mean(ds["FLNS"][rng...],  dims=(1, )) )[1, :, :]
    global HFLX_SFC = (   mean(ds["SHFLX"][rng...], dims=(1, )) + mean(ds["LHFLX"][rng...], dims=(1, )) )[1, :, :]

    global (Ny, Nt) = size(FFLX_TOA)

end


IAET       = zeros(Float64, Ny, Nt)
EFLX_CONV  = zeros(Float64, Ny, Nt)

for t = 1:Nt

    FFLX_TOA[:, t] .*= lat_weight 
    FFLX_SFC[:, t] .*= lat_weight
    HFLX_SFC[:, t] .*= lat_weight
    EFLX_CONV[:, t] = - ( FFLX_TOA[:, t] - FFLX_SFC[:, t] - HFLX_SFC[:, t] )
    IAET[:, t] = integrate(y, EFLX_CONV[:, t])

end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("FFLX_TOA",  FFLX_TOA,  ("Ny", "time"), Dict()),
        ("FFLX_SFC",  FFLX_SFC,  ("Ny", "time"), Dict()),
        ("HFLX_SFC",  HFLX_SFC,  ("Ny", "time"), Dict()),
        ("EFLX_CONV", EFLX_CONV, ("Ny", "time"), Dict()),
        ("IAET",      IAET,      ("Ny", "time"), Dict()),
        ("FFLX_TOA_mean",  mean(FFLX_TOA, dims=(2,))[:, 1],  ("Ny", ), Dict()),
        ("FFLX_SFC_mean",  mean(FFLX_SFC, dims=(2,))[:, 1],  ("Ny", ), Dict()),
        ("HFLX_SFC_mean",  mean(HFLX_SFC, dims=(2,))[:, 1],  ("Ny", ), Dict()),
        ("EFLX_CONV_mean", mean(EFLX_CONV, dims=(2,))[:, 1], ("Ny", ), Dict()),
        ("IAET_mean",      mean(IAET, dims=(2,))[:, 1],      ("Ny", ), Dict()),
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

















