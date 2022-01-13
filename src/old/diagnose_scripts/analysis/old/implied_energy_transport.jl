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

    global lat_weight = 2π * Re^2.0 * cos.(deg2rad.(lat))
    global ϕ          = deg2rad.(lat)

    global L_idx = (mask .== 1)
    global O_idx = (mask .== 0)

end

Dataset(parsed["data-file"], "r") do ds
 
    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12
    rng = (:,:,beg_t:end_t) 

    global A_flx_2D = (
        FFLX_TOA = ( - mean(ds["FSNT"][rng...], dims=(3, ))  + mean(ds["FLNT"][rng...],  dims=(3, )) )[:, :, 1],
        FFLX_SFC = ( - mean(ds["FSNS"][rng...], dims=(3, ))  + mean(ds["FLNS"][rng...],  dims=(3, )) )[:, :, 1],
        HFLX_SFC = (   mean(ds["SHFLX"][rng...], dims=(3, )) + mean(ds["LHFLX"][rng...], dims=(3, )) )[:, :, 1],
    )
    
    global (Nx, Ny) = size(A_flx_2D.FFLX_TOA)

    O_flx_2D = (
        FFLX_SFC = zeros(Nx, Ny),
        HFLX_SFC = zeros(Nx, Ny),
    )

    L_flx_2D = (
        FFLX_SFC = zeros(Nx, Ny),
        HFLX_SFC = zeros(Nx, Ny),
    )

    O_flx_2D.FFLX_SFC[O_idx] .= A_flx_2D.FFLX_SFC[O_idx]
    O_flx_2D.HFLX_SFC[O_idx] .= A_flx_2D.HFLX_SFC[O_idx]
    
    L_flx_2D.FFLX_SFC[L_idx] .= A_flx_2D.FFLX_SFC[L_idx]
    L_flx_2D.HFLX_SFC[L_idx] .= A_flx_2D.HFLX_SFC[L_idx]


    # zonal average
    global A_flx = (
        FFLX_TOA = mean(A_flx_2D.FFLX_TOA, dims=(1,))[1,:] .* lat_weight,
        FFLX_SFC = mean(A_flx_2D.FFLX_SFC, dims=(1,))[1,:] .* lat_weight,
        HFLX_SFC = mean(A_flx_2D.HFLX_SFC, dims=(1,))[1,:] .* lat_weight,
    )

    global O_flx = (
        FFLX_SFC = mean(O_flx_2D.FFLX_SFC, dims=(1,))[1,:] .* lat_weight,
        HFLX_SFC = mean(O_flx_2D.HFLX_SFC, dims=(1,))[1,:] .* lat_weight,
    )
    
    global L_flx = (
        FFLX_SFC = mean(L_flx_2D.FFLX_SFC, dims=(1,))[1,:] .* lat_weight,
        HFLX_SFC = mean(L_flx_2D.HFLX_SFC, dims=(1,))[1,:] .* lat_weight,
    )

end


A_EFLX_CONV = - ( A_flx.FFLX_TOA - A_flx.FFLX_SFC - A_flx.HFLX_SFC )
O_EFLX_CONV = - ( O_flx.FFLX_SFC + O_flx.HFLX_SFC )
L_EFLX_CONV = - ( L_flx.FFLX_SFC + L_flx.HFLX_SFC )

A_IET = integrate(ϕ, A_EFLX_CONV)
O_IET = integrate(ϕ, O_EFLX_CONV)
L_IET = integrate(ϕ, L_EFLX_CONV)

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Ny", Ny)

    for (varname, vardata, vardim, attrib) in [
        ("A_FFLX_TOA",  A_flx.FFLX_TOA,  ("Ny",), Dict()),
        ("A_FFLX_SFC",  A_flx.FFLX_SFC,  ("Ny",), Dict()),
        ("A_HFLX_SFC",  A_flx.HFLX_SFC,  ("Ny",), Dict()),

        ("O_FFLX_SFC",  O_flx.FFLX_SFC,  ("Ny",), Dict()),
        ("O_HFLX_SFC",  O_flx.HFLX_SFC,  ("Ny",), Dict()),

        ("L_FFLX_SFC",  L_flx.FFLX_SFC,  ("Ny",), Dict()),
        ("L_HFLX_SFC",  L_flx.HFLX_SFC,  ("Ny",), Dict()),

        ("A_IET",       A_IET,           ("Ny",), Dict()),
        ("O_IET",       O_IET,           ("Ny",), Dict()),
        ("L_IET",       L_IET,           ("Ny",), Dict()),
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

















