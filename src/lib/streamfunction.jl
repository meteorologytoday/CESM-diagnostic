

function calStreamfunction(;
    dp       :: Array{T, 3},
    cos_lat  :: Array{T, 1},
    v        :: Array{T, 3},
) where T <: AbstractFloat

    Ny, Nz = size(v)
    Nzp1 = Nz + 1

    Ψ = zeros(T, Ny, Nzp1)
   
    vdp = view( sum(v .* dp, dims=1), 1, :, : )  # (lon, lev)
 
    wgt = reshape( 2π * Re * cos_lat / g, :, 1 ) 

    for j=1:Ny
        for k=1:Nzp1-1  # Integrating from the top
            Ψ[j, k+1] = Ψ[j, k] + vdp[j, k]
        end

    end

    Ψ .*= wgt

    return Ψ

end


