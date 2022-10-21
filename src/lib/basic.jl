using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON


function calPressure(;
    a  :: Array{T, 1},
    b  :: Array{T, 1},
    ps :: Union{T, Array{T, 2}},
    p0 :: T = 1e5,
) where T <: AbstractFloat
    

    if typeof(ps) <: Array
    
        s = [1 for i = 1:length(size(ps))]
        
        a = reshape(a, s..., :)
        b = reshape(b, s..., :)
        ps = reshape(ps, size(ps)..., 1)
        
    end

    p = a .* p0 .+ b .* ps

    return p
 
end

