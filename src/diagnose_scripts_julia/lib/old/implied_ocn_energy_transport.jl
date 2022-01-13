include("../../CoordTrans/CoordTrans_ESMF.jl")
include("./CESMReader.jl")

using .CoordTrans_ESMF
using .CESMReader
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
 
        "--ESMF-wgt-file"
            help = "ESMF generated domain file."
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
    
wi = CoordTrans_ESMF.readWeightInfo(parsed["ESMF-wgt-file"])

Dataset(parsed["domain-file"], "r") do ds

    global mask = ds["mask"][:] |> mreplace
    global area = ds["area"][:] |> mreplace
    global lat = ds["yc"][1, :] |> mreplace

    global lat_weight = 2π * Re^2.0 * cos.(deg2rad.(lat))
    global ϕ          = deg2rad.(lat)

    global is_ocn = mask .== 0.0
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
 
    _TFLUX_DIV_implied = getData(fh, "TFLUX_DIV_implied", (parsed["beg-year"], parsed["end-year"]), (:, :))

    global Nx, Ny, Nt = size(_TFLUX_DIV_implied)

    if mod(Nt, 12) != 0
        throw(ErrorException("Time should be a multiple of 12."))
    end

    global nyears = Int64(Nt / 12)
    println(format("We got {:d} years of data.", nyears))

    # Do fraction weighting
    _ECONV = zeros(Float64, Ny, Nt)

    @time for t=1:Nt
        sum_flux = 0.0
        sum_area = 0.0
        for i=1:Nx, j=1:Ny
            b = (i-1) + Nx * (j-1) + 1
            if is_ocn[i, j]
                _ECONV[j, t] += _TFLUX_DIV_implied[i, j, t] #* wi.frac_b[b] 
                sum_flux +=  _TFLUX_DIV_implied[i, j, t] * area[i, j]# * wi.frac_b[b]
                sum_area += area[i, j] #* wi.frac_b[b]
            end
        end


       println(t, " : ", sum_flux * ρc / sum_area)
        
    end

    _ECONV .*= ρc / Nx

    global IOET = zeros(Float64, Ny, Nt)

    for t = 1:Nt
        IOET[:, t] = integrate(ϕ, _ECONV[:, t] .* lat_weight)
    end


end



Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Ny", Ny)
    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("IOET", IOET, ("Ny", "time"), Dict()),
        ("IOET_AM",    mean(IOET, dims=(2,))[:, 1], ("Ny",), Dict()),
        ("IOET_AMSTD",  std(IOET, dims=(2,))[:, 1], ("Ny",), Dict()),
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

