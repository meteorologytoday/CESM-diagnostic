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
            help = "Ocean data file."
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

#    global O_idx = (mask .== 0)

end

Dataset(parsed["data-file"], "r") do ds
 
    beg_t = (parsed["beg-year"] - 1) * 12 + 1
    end_t = (parsed["end-year"] - 1) * 12 + 12
    rng = (:,:,beg_t:end_t) 

    getData = (varname) -> mean( replace(ds[varname][rng...], missing=>0.0, NaN=>0.0), dims=(1, ))[1, :, :]

    global neb = getData("neb")
    global Q_clim = getData("Q_clim")
    global qflx     = getData("qflx")
    global wT       = getData("wT") * ρc
    global nswflx   = getData("nswflx")
    global swflx    = getData("swflx")
    global dHdt    = getData("dHdt")

    
    global qflx2atm = replace(ds["qflx2atm"][rng...], missing=>0.0, NaN=>0.0)
    qflx2atm[qflx2atm .< 0.0] .= 0.0
    qflx2atm = mean( qflx2atm, dims=(1, ))[1, :, :]
    
    global (Ny, Nt) = size(neb)

end

IET_neb       = zeros(Float64, Ny, Nt)
IET_Q_clim    = zeros(Float64, Ny, Nt)
IET_qflx      = zeros(Float64, Ny, Nt)
IET_wT        = zeros(Float64, Ny, Nt)
IET_nswflx    = zeros(Float64, Ny, Nt)
IET_swflx     = zeros(Float64, Ny, Nt)
IET_dHdt      = zeros(Float64, Ny, Nt)

for t = 1:Nt
    IET_neb[:, t]    = integrate(ϕ, neb[:, t] .* lat_weight)
    IET_Q_clim[:, t] = integrate(ϕ, Q_clim[:, t] .* lat_weight)
    IET_qflx[:, t]   = integrate(ϕ, qflx[:, t] .* lat_weight)
    IET_wT[:, t]     = integrate(ϕ, wT[:, t] .* lat_weight)
    IET_nswflx[:, t] = integrate(ϕ, nswflx[:, t] .* lat_weight)
    IET_swflx[:, t]  = integrate(ϕ, swflx[:, t] .* lat_weight)
    IET_dHdt[:, t]   = integrate(ϕ, dHdt[:, t] .* lat_weight)
end

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "Nx",  1)
    defDim(ds, "Ny", Ny)
    defDim(ds, "Nz",  1)
    defDim(ds, "time", Inf)

    for (varname, vardata, vardim, attrib) in [
        ("IET_neb",        reshape(IET_neb,    1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("IET_Q_clim",     reshape(IET_Q_clim, 1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("IET_qflx",       reshape(IET_qflx,   1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("IET_wT",         reshape(IET_wT,     1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("IET_nswflx",     reshape(IET_nswflx, 1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("IET_swflx",      reshape(IET_swflx,  1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("IET_dHdt",       reshape(IET_dHdt,   1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("neb",            reshape(neb,        1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("Q_clim",         reshape(Q_clim,     1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("qflx",           reshape(qflx,       1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("wT",             reshape(wT,         1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("nswflx",         reshape(nswflx,     1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("swflx",          reshape(swflx,      1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
        ("dHdt",           reshape(dHdt,       1, Ny, 1, Nt), ("Nx", "Ny", "Nz", "time"), Dict()),
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

