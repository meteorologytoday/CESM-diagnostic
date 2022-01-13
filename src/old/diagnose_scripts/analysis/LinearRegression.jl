

function LinearRegression(
    x :: AbstractArray{T, 1},
    y :: AbstractArray{T, 1};
    order :: Integer = 1,
) where T <: AbstractFloat 

    if order < 0
        throw(ErrorException("Parameter order must be non-negative."))
    end

    N = length(x)

    bases = order + 1


    ϕ = zeros(N, bases)

    for i = 1:bases

        if i == 1
            ϕ[:, 1] .= 1.0
        else
            ϕ[:, i] .= x.^(i-1)
        end

    end

    # ϕ β = y => β = ϕ \ y

    return ϕ \ y

end

function detrend(
    x :: AbstractArray{T, 1},
    y :: AbstractArray{T, 1};
    order :: Integer = 1,
) where T <: AbstractFloat

    if order < 0
        throw(ErrorException("Parameter order must be non-negative."))
    end
    
    bases = order + 1

    β = LinearRegression(x, y; order=order)
    
    result = copy(y)
    total_mean = 0.0
    for i = 1:bases
        result .-= β[i] * x.^(i-1)
        total_mean += β[i]/ i * (x[end]^i - x[1]^i) 
    end

    result .+= total_mean / (x[end] - x[1])

    return result

end
