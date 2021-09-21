using NCDatasets
using Formatting
using PyPlot

#
# Global Diagnose
#
# X v.s. latitude
#
# - Heat transport
# - Precipitation
#
# X v.s. time
# 
# - Jet stream position
# - Precipitation
#
casename = "SMARTSLAB_SOM_lowres"
folder = joinpath("atm", "hist")
getFn0 = (y, m) -> joinpath(folder, format("$casename.cam.h0.00{:02d}-{:02d}.nc", y, m))

y_rngs = [(1, 20), (1,10), (11, 20)]


for (y_beg, y_end) in y_rngs

    local mht = nothing
    
    for y = y_beg:y_end, m = 1:12

        ds = Dataset(fn, "r")

        if mht == nothing
            mht = zeros(Float64, size(ds["VT"])...)
        end
        
        mht
        
        
        fn = getFn(y, m)
        
        close(ds)
    end
 
end
