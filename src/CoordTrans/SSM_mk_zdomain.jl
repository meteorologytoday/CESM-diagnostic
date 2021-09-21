using NCDatasets
using Formatting

include("./SSM_z_res.jl")

fn_o = ARGS[1]


Nz = length(zs_SSM) - 1
N_zs = length(zs_SSM)

Dataset(fn_o, "c") do ds

    defDim(ds, "Nz", Nz)
    defDim(ds, "zs", N_zs)

    defVar(ds, "zs", zs_SSM, ("zs",))
    
end
