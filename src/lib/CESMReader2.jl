module CESMReader2

    using NCDatasets
    using Formatting
    
    import ..normTime, ..absTime

    export FileHandler, getData  

    """
    This function reads variables across a set of files and average the read variables.
    """
    function readData(
        filenames      :: Array{<:AbstractString, 1},
        varnames       :: Union{Array{<:AbstractString, 1}, Nothing} = nothing,
        fixed_varnames :: Union{Array{<:AbstractString, 1}, Nothing} = nothing;
        conform_dtype  :: Union{DataType, Nothing} = nothing,
        verbose        :: Bool = False,
    )

        verbose && println("conform_dtype: ", conform_dtype)

        init = true
        data = Dict()

        for filename in filenames

            if verbose
                println(format("Reading file: {:s}", filename))
            end

            ds = Dataset(filename, "r")

            if init

                if varnames == nothing
                    varnames = keys(ds)
                end

                if fixed_varnames != nothing
                    for fixed_varname in fixed_varnames
                        v = ds[fixed_varname][:]

                        if typeof(v) <: Array
                            v = nomissing(v, NaN)
                        end

                        if conform_dtype != nothing
                            if typeof(v) <: Array
                                if eltype(v) != conform_dtype
                                    verbose && println("Convert $fixed_varname from $(eltype(v)) to $conform_dtype")
                                    v = convert(Array{conform_dtype}, v)
                                end
                            else

                                if typeof(v) != conform_dtype
                                    verbose && println("Convert $fixed_varname from $(typeof(v)) to $conform_dtype")
                                    v = convert(conform_dtype, v)
                                end
                            end
                        end
     
                        data[fixed_varname] = v
                    end
                end 
            end 
            
            for varname in varnames
                
                v = ds[varname][:]
                
                if typeof(v) <: Array
                    v = nomissing(v, NaN)
                end

               
                if init

                    if conform_dtype != nothing
                        if typeof(v) <: Array
                            if eltype(v) != conform_dtype
                                verbose && println("Convert $varname from $(eltype(v)) to $conform_dtype")
                                v = convert(Array{conform_dtype}, v)
                            end
                        else
                            if typeof(v) != conform_dtype
                                verbose && println("Convert $varname from $(typeof(v)) to $conform_dtype")
                                v = convert(conform_dtype, v)
                            end
                        end
                    end
     
                    data[varname] = v
                else
                    data[varname] .+= v
                end
            end
            
            close(ds) 
            init = false
        end

        cnt = length(filenames)
        for (k, v) in data
            if typeof(v) <: Array 
                v ./= cnt
            else
                v /= cnt
            end
        end
        
        return data
    end

    function iterData(
        f            :: Function,
        filename_format :: String,
        varnames     :: Array{<:AbstractString, 1},
        beg_time     :: Union{Tuple, Array},
        end_time     :: Union{Tuple, Array};
        fixed_varnames  :: Union{Array{<:AbstractString, 1}, Nothing} = nothing,
        sampling     :: Symbol = :do_nothing,
        skip         :: Union{Tuple, Array} = (0, 1),
        subskips  :: Integer = 1,
        subskip      :: Union{Tuple, Array} = (0, 0),
        conform_dtype :: Union{DataType, Nothing} = nothing,
        verbose      :: Bool = false,
    )

        beg_time  = normTime(beg_time)    
        end_time  = normTime(end_time)
        skip      = normTime(skip)
        subskip   = normTime(subskip)

        if sampling == :do_nothing
        
        elseif sampling == :annual_mean
            skip = (1, 0)
            subskips = 12
            subskip = (0, 1)
        elseif sampling == :fixed_month
            skip = (1, 0)
        end



        grps = []
        grp = nothing
        # Group filenames
        iterFilenames(
            filename_format,
            beg_time,
            end_time,
            skip = skip,
            subskips = subskips,
            subskip = subskip,
        ) do filename, y, m, skip_cnt, subskip_cnt

            if grp == nothing
                grp = Array{String}(undef,0)
            end
            
            push!(grp, filename)
            
            if subskip_cnt == subskips
                 push!(grps, grp)
                 data = readData(grp, varnames, fixed_varnames; verbose=verbose, conform_dtype=conform_dtype)
                 f(data, grp, skip_cnt)
                 grp = nothing
            end

        end

    end

    function iterFilenames(
        f               :: Function,
        filename_format :: String,
        beg_time     :: Union{Tuple, Array},
        end_time     :: Union{Tuple, Array};
        skip         :: Union{Tuple, Array} = (0, 1),
        subskips  :: Integer = 1,
        subskip      :: Union{Tuple, Array} = (0, 0),
    )

        beg_time  = normTime(beg_time)    
        end_time  = normTime(end_time)
 
        beg_y = beg_time[1]
        beg_m = beg_time[2]
        
        end_y = end_time[1]
        end_m = end_time[2]

        beg_abst = absTime(beg_time)
        end_abst = absTime(end_time)

        dt = end_abst - beg_abst + 1
        
        if dt <= 0
            throw(ErrorException("End time should be larger than begin time"))
        end

        skip_abst = absTime(skip)
        subskip_abst = absTime(subskip)

        for (skip_cnt, abst) in enumerate(beg_abst:skip_abst:end_abst)
            
            for subskip_cnt = 1:subskips
                
                tmp_abst = abst + (subskip_cnt-1) * subskip_abst
                y, m = normTime((0, tmp_abst))

                filename = format(filename_format, y, m)
                if_continue = f(filename, y, m, skip_cnt, subskip_cnt)

                if if_continue == false
                    println("Break the iteration.")
                    break
                end

            end
        end            
        
    end
end
