using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON

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

        "--output-file"
            help = "Output file."
            arg_type = String
            required = true

        "--domain-file"
            help = "Ocn domain file."
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

function mreplace(x)
    return replace(x, missing=>NaN)
end


Dataset(parsed["domain-file"], "r") do ds
    global area = mreplace(ds["area"][:])
    global lat  = mreplace(ds["yc"][:])

    # Avoid grid points right on the equator.
    global tropic_NH_idx  = (   0.0 .<= lat .<= 20.0 )
    global tropic_SH_idx  = ( -20.0 .<= lat .<=  0.0 )
    
    global tropic_idx = tropic_NH_idx .| tropic_SH_idx

    
    global tropic_area = area[tropic_idx]
    global tropic_NH_area = area[tropic_NH_idx]
    global tropic_SH_area = area[tropic_SH_idx]


    global total_tropic_area    = sum(tropic_area)
    global total_tropic_NH_area = sum(tropic_NH_area)
    global total_tropic_SH_area = sum(tropic_SH_area)
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
 
    PRECC, PRECL = getData(fh, ["PRECC", "PRECL"], (parsed["beg-year"], parsed["end-year"]), (:, :))
    
    PREC = PRECC + PRECL


    if any(PREC .< 0)
        throw(ErrorException("OHOH"))
    end

    Nt = end_t - beg_t + 1

    global years = Int(Nt/12)
    global PAI         = zeros(Float64, years)
    global NH_mean     = zeros(Float64, years)
    global SH_mean     = zeros(Float64, years)
    global tropic_mean = zeros(Float64, years)

    for y = 1:years
        
        PREC_m = mean( PREC[ :, :, ((y-1)*12+1):(y*12)] , dims=3 )[:, :, 1]


 
        NH_m = sum(PREC_m[tropic_NH_idx] .* tropic_NH_area) / total_tropic_NH_area
        SH_m = sum(PREC_m[tropic_SH_idx] .* tropic_SH_area) / total_tropic_SH_area 
        m    = sum(PREC_m[tropic_idx]    .* tropic_area   ) / total_tropic_area 
       
        #P = PREC_m[tropic_idx]
        #println( format("Max: {:e}, min: {:e}, mean: {:e}, std: {:e}", maximum(P), minimum(P), mean(P), std(P)) )
        
        NH_mean[y] = NH_m
        SH_mean[y] = SH_m
        tropic_mean[y] = m

        PAI[y] = ( NH_m - SH_m ) / m

    end

end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "year", years)

    for (varname, vardata, vardim, attrib) in [
        ("PAI", PAI, ("year",), Dict()),
        ("NH_mean", NH_mean, ("year",), Dict()),
        ("SH_mean", SH_mean, ("year",), Dict()),
        ("tropic_mean", tropic_mean, ("year",), Dict()),
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
