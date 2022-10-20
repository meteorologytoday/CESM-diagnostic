using NCDatasets
using Formatting
using ArgParse
using Statistics
using JSON


function computePressure(;
    A  :: Array{T, 1},
    B  :: Array{T, 1},
    ps :: Union{T, Array{T, 1}, Array{T, 2}},
    p0 :: T = 1e5,
) where T <: AbstractFloat
    

    if ps <: Array
    
        s = [1 for i = 1:length(size(ps))]
        
        A = reshape(A, s..., :)
        B = reshape(B, s..., :)
        ps = reshape(ps, size(ps)..., 1)
        
    end

    p = A .* p0 .+ B .* ps

    return p
 
end

