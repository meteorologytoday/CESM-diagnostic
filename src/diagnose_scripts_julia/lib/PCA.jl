module PCA

    include("LinearRegression.jl")
    using LinearAlgebra

    function helper_findPCAs(
        X    :: AbstractArray{T, 2};
        num  :: Integer = 1,  # number of eignevectors wish to return
    ) where T <: AbstractFloat


        # dim means the spatial dimension of X
        # N means the number of sampling (time, for example)
        dim, N = size(X)


        Σ = Symmetric(X * X')
        
        println("Dimension of Σ : ", size(Σ))
        println("Any missing data? ", any(isnan.(Σ))) 

        if any(isnan.(Σ))
            throw(ErrorException("Data contains NaN!"))
        end        

        @time F = eigen(Σ)

        order = collect(1:dim)
        sort!(order; by = i -> F.values[i], rev=true)

        evs = zeros(T, dim, num)
        for i = 1:num
            evs[:, i] = normalize(F.vectors[:, order[i]])
        end


        return evs

    end


    # This function removes seasonality and detrend the input data
    function findPCAs(
        raw_data,
        EOF_idx;
        modes::Integer
    )

        data = copy(raw_data)

        data_size = size(data)
        field_size = data_size[1:end-1]
        N  = reduce(*, field_size)
        Nt = data_size[end]
        flat_data = reshape(data, N, Nt)
        flat_EOF_idx = reshape(EOF_idx, :) 

        # construct mapping of PCA
        grid_numbering = reshape( collect(1:N), field_size... )
        EOF_mapping = grid_numbering[EOF_idx]  # The i-th reduced grid idx onto the original ?-th grid

        EOF_pts = sum(EOF_idx)
        EOF_input = zeros(Float64, EOF_pts, Nt)
        t_vec = collect(eltype(EOF_input), 1:Nt)

        for t = 1:Nt
            _data = view(flat_data, :, t)
            EOF_input[:, t] = _data[flat_EOF_idx] 
        end

        for i=1:EOF_pts
            EOF_input[i, :] = detrend(t_vec, view(EOF_input, i, :), order=2)
        end

        # remove seasonality
        for i=1:EOF_pts
            vw = view(EOF_input, i, :)
            rmSeasonality!(vw; period=12)
        end

        # Doing PCAs
        println("Solving for PCA...")
        eigen_vectors = helper_findPCAs(EOF_input, num=modes)

        PCAs = zeros(Float64, N, modes)
        PCAs .= NaN

        for i = 1:EOF_pts
            PCAs[EOF_mapping[i], :] = eigen_vectors[i, :]
        end

        # Project anomalies onto PCAs
        PCAs_ts = (transpose(eigen_vectors) * EOF_input) # dimension = (modes, Nt)
#        for m = 1:modes
#            PCAs_ts[m, :] ./= std(view(PCAs_ts, m, :))
#        end

        return reshape(PCAs, field_size..., modes), PCAs_ts
    end



end
