include("../src/lib/CESMTools.jl")

using Formatting
using NCDatasets
using .CESMTools


ct = CESMTools


ct.CESMReader2.iterFilenames(
    "test_data/qco2_SOM.cam.h0.{:04d}-{:02d}.nc",
    (350, 0),
    (353, 12);
    skip = (0, 12),
    subskip = (0, 1),
    subskips = 3,
) do filename, y, m, skip_cnt, subskip_cnt
    
    println(format("[{:04d}, {:02d}, {:d}, {:d}] {:s}", y, m, skip_cnt, subskip_cnt, filename))

    #=    
    ds = Dataset(filename, "r")
    
    v = convert(Array{Float64}, nomissing( ds["V"][:] , NaN ))
    a = nomissing( ds["hyai"][:] , NaN )
    b = nomissing( ds["hybi"][:] , NaN )
    ps = convert(Array{Float64}, nomissing( ds["PS"][:] , NaN ))
    p0 = ds["P0"][:]
    
    close(ds)

    =#
    #p = ct.calPressure(a=a, b=b, ps=ps, p0=p0)


end
