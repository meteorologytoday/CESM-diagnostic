module PCA

    using LinearAlgebra

    function findPCAs(
        X    :: AbstractArray{T, 2};
        num  :: Integer = 1
    ) where T <: AbstractFloat


        dim, N = size(X)


        Σ = Symmetric(X * X')
        
        println("Dimension of Σ : ", size(Σ))
        println("Any missing data? ", any(isnan.(Σ))) 

        if any(isnan.(Σ))
            throw(ErrorException("Data contains NaN!"))
        end        

        @time F = eigen(Σ)

        #println(F.values)
        #println(length(F.values))

        order = collect(1:dim)
        sort!(order; by = i -> F.values[i], rev=true)

        evs = zeros(T, dim, num)
        for i = 1:num
            evs[:, i] = normalize(F.vectors[:, order[i]])
        end


        return evs

    end

end
