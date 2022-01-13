

function invertStreamfunction(
    lats :: AbstractArray{Float64, 1}, # in rad
    levs :: AbstractArray{Float64, 1},
    v    :: AbstractArray{Float64, 2};
    g0   :: AbstractFloat = 9.8,
    Re   :: AbstractFloat = 6371000.0,
)

    if (length(lats), length(levs)-1) != size(v)
        throw(ErrorException("Wrong dimension"))
    end

    dm = (levs[2:end] - levs[1:end-1]) / g0
    ψ  = zeros(Float64, length(lats), length(levs))

    for i = 1:length(lats)
        for k = size(v)[2]-1:-1:1
            ψ[i, k] = ψ[i, k+1] - v[i, k] * cos(lats[i]) * dm[k]
        end 
    end

    ψ .*= 2.0*π * Re
    return ψ
end
