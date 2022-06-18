include("../CESM-diagnostic/src/misc/RunCommands.jl")

using .RunCommands
using Formatting

include("setup.jl")


gonna_do = keys(cases)

#gonna_do = ["qco2_SOM", "qco2_MLM", "qco2_EMOM", "qco"]

year_skip = 10

varlist = join(["hi", "aice",], ",")

# Making annual average
for (casename, caseinfo) in cases

    if ! ( casename in gonna_do )
        println("Not gonna do $casename.")
        continue
    end

    println("Doing casename: $casename")

    output_dir_case = "$output_dir/$casename/ice"
    mkpath(output_dir_case)


    yrng = caseinfo["yrng"]
    println("Doing year range: $(yrng[1]) to $(yrng[2]). year_skip = $year_skip")
    data_path = "$archive_root/$casename/ice/hist"

    for y = yrng[1]:year_skip:yrng[2]
        
        println("Doing year: ", y, "\r")
        input_file  = format("$data_path/$casename.cice.h.{{{:04d}..{:04d}}}-{{01..12}}.nc", y, y + year_skip - 1)
        output_file = format("$output_dir_case/$casename.cice.{:04d}.nc", y)        
            

        if isfile(output_file)
            println("File `$output_file` exists. Skip this.")
        else
            pleaseRun(`bash -c "ncra -O -v $(varlist) $input_file $output_file"`)
        end

    end
end

println("Done.")
