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
#    global mask_idx = (mask .== 0.0)
end

let
    global swflx, nswflx, TFLUX_DIV_implied, qflx, TSAS_clim, TFLUX_bot

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
 
    swflx, nswflx, TFLUX_DIV_implied, qflx, TSAS_clim, TFLUX_bot = getData(fh, ["swflx", "nswflx", "TFLUX_DIV_implied", "qflx", "TSAS_clim", "TFLUX_bot"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    swflx             = mean(swflx,             dims=(3, ))[:, :, 1]
    nswflx            = mean(nswflx,            dims=(3, ))[:, :, 1]
    TFLUX_DIV_implied = mean(TFLUX_DIV_implied, dims=(3, ))[:, :, 1]
    qflx              = mean(qflx,              dims=(3, ))[:, :, 1]
    TSAS_clim         = mean(TSAS_clim,         dims=(3, ))[:, :, 1]
    TFLUX_bot         = mean(TFLUX_bot,         dims=(3, ))[:, :, 1]

#=
    swflx[mask_idx] .= NaN
    nswflx[mask_idx] .= NaN
    TFLUX_DIV_implied[mask_idx] .= NaN
    qflx[mask_idx] .= NaN
    TSAS_clim[mask_idx] .= NaN
    TFLUX_bot[mask_idx] .= NaN
=#

    global (Nx, Ny) = size(swflx)

end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Nx", Nx)
    defDim(ds, "Ny", Ny)

    for (varname, vardata, vardim, attrib) in [
        ("swflx",             swflx,             ("Nx", "Ny"), Dict()),
        ("nswflx",            nswflx,            ("Nx", "Ny"), Dict()),
        ("TFLUX_DIV_implied", TFLUX_DIV_implied, ("Nx", "Ny"), Dict()),
        ("qflx",              qflx,              ("Nx", "Ny"), Dict()),
        ("TSAS_clim",         TSAS_clim,         ("Nx", "Ny"), Dict()),
        ("TFLUX_bot",         TFLUX_bot,         ("Nx", "Ny"), Dict()),
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

















