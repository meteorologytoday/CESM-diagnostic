using NCDatasets
using Formatting

fn_o = ARGS[1]

zs = collect(Float64, 0:-50:-1000)
Nz = length(zs) - 1
N_zs = length(zs)

Dataset(fn_o, "c") do ds

    defDim(ds, "Nz", Nz)
    defDim(ds, "zs", N_zs)

    defVar(ds, "zs", zs, ("zs",))
    
end
