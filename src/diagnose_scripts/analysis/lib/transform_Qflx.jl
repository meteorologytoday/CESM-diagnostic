include("map_transform.jl")

using NCDatasets
using .MapTransform

using ArgParse
using JSON

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin

        "--input-file"
            help = "Input Qflux file."
            arg_type = String
            required = true

        "--output-file"
            help = "Output Qflux file."
            arg_type = String
            required = true

        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true

        "--varname-qflx"
            help = "Varname of Q-flux."
            arg_type = String
            required = true

    end

    return parse_args(ARGS, s)
end

println("Running ", @__FILE__)

parsed = parse_commandline()
print(json(parsed, 4))

Dataset(parsed["domain-file"], "r") do ds
    global area = replace(ds["area"][:], missing => NaN)
    global mask = replace(ds["mask"][:], missing => NaN)
    global lat  = replace(ds["yc"][:], missing => NaN)
end

lat_bnd = collect(Float64, -90:1:90)

println("Before: sum_area = ", sum(area))
area *= 4π * (6371e3)^2 / sum(area)
println("After sum_area = ", sum(area))

r = MapTransform.Relation(
    lat = lat,
    area = area,
    mask = mask,
    lat_bnd = lat_bnd,
)

_proxy = area * 0 .+ 1.0
sum_valid_area = MapTransform.∫∂a(r, _proxy)[end]

println("Sum of valid area: ", sum_valid_area, "; ratio: ", sum_valid_area / sum(area))

Dataset(parsed["input-file"], "r") do ids

    Nt = ids.dim["time"]
    global Q_ano  = zeros(Float64, length(lat_bnd)-1, Nt)
    global ∫Q_ano∂a = zeros(Float64, length(lat_bnd), Nt)
    global Q_avg = zeros(Float64, Nt)

    for t=1:Nt

        _data = nomissing(ids[parsed["varname-qflx"]][:, :, t], NaN)
        Q_avg[t] = MapTransform.∫∂a(r, _data)[end] / sum_valid_area

        _data .-= Q_avg[t]
        
        Q_ano[:, t] = MapTransform.transform(r, _data) 
        ∫Q_ano∂a[:, t] = MapTransform.∫∂a(r, _data)

    end

end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "lat_bnd", length(r.lat_bnd))
    defDim(ds, "lat",     length(r.lat_bnd)-1)
    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("lat_bnd",   lat_bnd, ("lat_bnd",         ), Dict()),
        ("Q_avg",       Q_avg, ("time", ), Dict()),
        ("Q_ano",       Q_ano, ("lat",     "time", ), Dict()),
        ("intQ_ano", ∫Q_ano∂a, ("lat_bnd", "time", ), Dict()),
    ]
        println("Doing varname:", varname)
        var = defVar(ds, varname, Float64, vardim)
        var.attrib["_FillValue"] = 1e20
        
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
