using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON

include("constants.jl")

function mreplace(x)
    return replace(x, missing=>NaN)
end

function calΨ!(
    ilev  :: Array{Float64, 1},
    lat   :: Array{Float64, 1},
    v     :: Array{Float64, 2},
    Ψ :: Array{Float64, 2},
)

    Ny, Nz = size(v)
    Nz_bnd = length(ilev)
    dp = ilev[1:end-1] - ilev[2:end]
        
    Ψ[:, Nz_bnd] .= 0.0
    for j=1:Ny
        for k=Nz_bnd-1:-1:1
            Ψ[j, k] = Ψ[j, k+1] + dp[k] * v[j, k]
        end

        Ψ[j, :] .*= 2π * Re * cos(lat[j] * π/180.0) / g
    end

end

function parse_commandline()

    s = ArgParseSettings()
    @add_arg_table s begin
        "--input-data-file-prefix"
            help = "Input data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
            arg_type = String
            required = true
 
        "--output-data-file-prefix"
            help = "Output data filename prefix including folder and path until the timestamp. File extension `nc` is assumed."
            arg_type = String
            required = true
 
        "--domain-file"
            help = "Domain file."
            arg_type = String
            required = true
 
        "--ilev-varname"
            help = "Variable name of pressure level. Assume in unit of hPa."
            arg_type = String
            default = "ilev"

        "--V-varname"
            help = "Variable name of meridional velocity"
            arg_type = String
            default = "V"

        "--beg-year"
            help = "Year of begin."
            arg_type = Int64
            required = true

        "--end-year"
            help = "Year of end."
            arg_type = Int64
            required = true


        "--overwrite"
            action = :store_true

    end

    return parse_args(ARGS, s)
end

parsed = parse_commandline()
print(json(parsed, 4))

Dataset(parsed["domain-file"], "r") do ds
    global lon = replace(ds["xc"][:, 1], missing=>NaN)
    global lat = replace(ds["yc"][1, :], missing=>NaN)
end

Ψ   = nothing
ilev = nothing
for y=parsed["beg-year"]:parsed["end-year"], m=1:12
    
    i_filename = format("{:s}{:04d}-{:02d}.nc", parsed["input-data-file-prefix"], y, m)
    o_filename = format("{:s}{:04d}-{:02d}.nc", parsed["output-data-file-prefix"], y, m)


    if !isfile(o_filename) || parsed["overwrite"]



        Dataset(i_filename, "r") do ds
   
            v = convert(Array{Float64}, nomissing(ds[parsed["V-varname"]][:, :, 1]))

            if ilev == nothing
                global Ny, Nz = size(v)
                global ilev = ( ds[parsed["ilev-varname"]][:] |> mreplace ) * 100.0

                global Ψ = zeros(Float64, Ny, length(ilev))
            end

            calΨ!(ilev, lat, v, Ψ)

            Dataset(o_filename, "c") do ds
                defDim(ds, "Ny", Ny)
                defDim(ds, "ilev", length(ilev))
                defDim(ds, "time", Inf)
                for (varname, vardata, vardim, attrib) in [
                    ("psi", Ψ, ("Ny", "ilev"), Dict()),
                    ("ilev", ilev, ("ilev",), Dict()),
                ]

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
            println("Output: ", o_filename)
        end     

    end



end

