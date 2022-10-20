include("../src/lib/CESMTools.jl")

using Formatting
using NCDatasets
using .CESMTools


ct = CESMTools

ct.CESMReader2.iterData(
    "test_data/qco2_SOM.cam.h0.{:04d}-{:02d}.nc",
    ["PS", "V"],
    (351, 0),
    (353, 12);
    fixed_varnames = ["hyai", "hybi", "P0"],
    skip = (0, 12),
    subskip = (0, 1),
    subskips = 3,
    verbose = true,
    conform_dtype = Float64,
) do d, filenames, skip_cnt
    
    println(format("skip_cnt = {:d}", skip_cnt))
    
    p = ct.calPressure(a=d["hyai"], b=d["hybi"], ps=d["PS"], p0=d["P0"])


end
