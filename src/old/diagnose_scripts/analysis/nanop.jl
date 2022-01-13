using Statistics: mean


function nansum(
    x;
    dims :: Union{Nothing, Tuple} = nothing,
)

    y = copy(x)

    nan_idx    = isnan.(y)
    finite_idx = isfinite.(y)

    y[nan_idx] .= 0.0

    if dims == nothing
        return sum(y)
    else
        return sum(y, dims=dims)
    end
end

function nanmean(
    x;
    dims :: Union{Nothing, Tuple} = nothing,
)

    y = copy(x)

    nan_idx    = isnan.(y)
    finite_idx = isfinite.(y)

    y[nan_idx] .= 0.0
    if dims == nothing
        return sum(y) ./ sum(finite_idx)
    else
        return sum(y, dims=dims) ./ sum(finite_idx, dims=dims)
    end
end
