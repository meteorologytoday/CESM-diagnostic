module CESMReader2

    using NCDatasets
    using Formatting
    export FileHandler, getData  

    include("nanop.jl")


    function iterFilenames(
        f               :: Function,
        filename_format :: String,
        year_rng        :: Union{Tuple, Array},
    )

        beg_y = year_rng[1]
        end_y = year_rng[2]

        beg_m = 1
        end_m = 12

        beg_t = (beg_y - 1) * 12 + beg_m - 1
        end_t = (end_y - 1) * 12 + end_m - 1

        months = end_t - beg_t + 1
        
        if months <= 0
            throw(ErrorException("End time should be larger than begin time"))
        end

        if ! ( ( 1 <= beg_m <= 12 ) && ( 1 <= end_m <= 12 ) )
            throw(ErrorException("Invalid month"))
        end

        for y in beg_y:end_y, m in beg_m:end_m

            current_t = (y-1) * 12 + (m-1) - beg_t + 1
            filename = format(filename_format, y, m)
            if_continue = f(filename, y, m)

            if if_continue == false
                println("Break the iteration.")
                break
            end
        end            
    
        
    end
end
