module CESMReader

    using NCDatasets
    using Formatting
    export FileHandler, getData  

    include("nanop.jl")

    mutable struct FileHandler
        filename_format :: String
        form   :: Symbol
        LENS_benchmark :: Bool

        function FileHandler(;
            filename_format :: String,
            form        :: Symbol = :YEAR_MONTH,
            LENS_benchmark :: Bool = false,
        )

            if ! (form in [:YEAR, :YEAR_MONTH]  )
                throw(ErrorException("Error: only two forms allowed. Either :YEAR or :YEAR_MONTH. Now we got " * string(form)))
            end

            return new(
                filename_format,
                form,
                LENS_benchmark,
            )
        end

    end

    function getData(
        handler  :: FileHandler,
        varnames :: Union{String, Array},
        year_rng :: Union{Tuple, Array},
        idxes...;
        verbose=true,
    )
        return _getData(handler, varnames, (year_rng[1], 1), (year_rng[2], 12), collect(idxes)...; verbose=verbose)
    end

    function _getData(
        handler  :: FileHandler,
        varnames :: Union{String, Array},
        beg_time :: Union{Tuple, Array},
        end_time :: Union{Tuple, Array},
        idxes...;
        verbose=true,
    )

        local only_one_variable = false

        if typeof(varnames) <: AbstractString
            only_one_variable = true
            varnames = [varnames]
        end

        if ! only_one_variable && length(idxes) == 1
            idxes = [ idxes[1] for _ in 1:length(varnames) ]  
        end

        if ( only_one_variable && length(idxes) > 1 ) || length(idxes) != length(varnames)
            println(varnames)
            println(idxes)
            throw(ErrorException("Number of idxes should match number of varnames or only 1 (applied to all varnames)."))
        end

        beg_y, beg_m = beg_time
        end_y, end_m = end_time

        beg_t = (beg_y - 1) * 12 + beg_m - 1
        end_t = (end_y - 1) * 12 + end_m - 1

        months = end_t - beg_t + 1
        
        if months <= 0
            throw(ErrorException("End time should be larger than begin time"))
        end

        if ! ( ( 1 <= beg_m <= 12 ) && ( 1 <= end_m <= 12 ) )
            throw(ErrorException("Invalid month"))
        end

        for k = 1:length(idxes)
            if length(idxes[k]) == 0
                throw(ErrorException("Spatial range not specified."))
            end
        end

        local data, new_idxes

        datas = Array{Any}(undef, length(varnames))
        new_idxes = Array{Any}(undef, length(varnames))

        if handler.form == :YEAR_MONTH
            
            flag_1s = [true for _ in 1:length(varnames)]

            for y in beg_y:end_y, m in beg_m:end_m

                current_t = (y-1) * 12 + (m-1) - beg_t + 1

                filename = format(handler.filename_format, y, m)
                verbose && println("Loading file: ", filename)
                ds = Dataset(filename, "r")

                for (k, varname) in enumerate(varnames)

                    partial_data = replace(ds[varname][idxes[k]..., 1], missing=>NaN)
                    if flag_1s[k]
                        new_size = size(partial_data)
                        new_idxes[k]  = [Colon() for _ in 1:length(new_size)]
                        datas[k] = zeros(Float64, new_size..., months)
                        datas[k] .= NaN
                        flag_1s[k] = false
                    end

                    datas[k][new_idxes[k]..., current_t] = partial_data

                end

                close(ds)

            end            
            
        elseif handler.form == :YEAR
     
            flag_1s = [true for _ in 1:length(varnames)]

            for y in beg_y:end_y

                current_t = (y-1) * 12 - beg_t
                
                filename = format(handler.filename_format, y)
                verbose && println("Loading file: ", filename)
                ds = Dataset(filename, "r")

                for (k, varname) in enumerate(varnames)

                    if y == beg_y
                        rng = (idxes[k]..., beg_m:12)
                    elseif y == end_y
                        rng = (idxes[k]..., 1:end_m)
                    else
                        rng = (idxes[k]..., 1:12)
                    end  

                    partial_data = nomissing(ds[varname][rng...])

                    if flag_1s[k]
                        new_size = size(partial_data)[1:end-1]
                        new_idxes[k]  = [Colon() for _ in 1:length(new_size)]
                        datas[k] = zeros(Float64, new_size..., months)
                        datas[k] .= NaN
                        flag_1s[k] = false
                    end

                    if y == beg_y
                        rng = beg_m:12
                    elseif y == end_y
                        rng = 1:end_m
                    else
                        rng = 1:12
                    end
                    
                    offset = (y-beg_y) * 12
                    datas[k][new_idxes[k]..., rng .+ offset] = partial_data
                  
                end

                close(ds)

            end

        end 

        return (only_one_variable) ? datas[1] : datas
    end

end
