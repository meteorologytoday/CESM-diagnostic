
function absTime(
    t :: Union{Tuple, Array}
)
    return t[1] * 12 + t[2]
end

function normTime(
    t :: Union{Tuple, Array}
)

    new_y = t[1] + floor(Integer, (t[2]-1) / 12)
    new_m = mod(t[2]-1, 12) + 1
    
    return [new_y, new_m]

end
