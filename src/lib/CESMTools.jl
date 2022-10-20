module CESMTools

    using NCDatasets
    using Formatting
    using Statistics
   
    include("CESMTime.jl") 
    include("CESMReader2.jl")
    include("constants.jl")
    include("basic.jl")
    include("streamfunction.jl")


end
