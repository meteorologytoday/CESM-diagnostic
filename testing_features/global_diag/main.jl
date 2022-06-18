include("../CESM-diagnostic/src/misc/RunCommands.jl")

using .RunCommands
using Formatting

archive_root = "/glade/scratch/tienyiao/archive"
output_dir = "output"

models = ["SOM", "MLM", "EMOM", "POP2"]
casenames = [ "qco2_$(model)" for model in models ]

yrngs = [
    (1, 100),
    (1, 30),
    (31, 60),
    (61, 90),
]

offset_years = [200, 200, 200, 0]

mkpath(output_dir)

varlist = join(["TEMP", "SALT",], ",")

# Making annual average
for (i, casename) in enumerate(casenames)
    
    println("Doing casename: $casename")

    yrng = [yrngs[i]...,] .+ offset_years[i]
    println("Doing year range: $(yrng[1]) to $(yrng[2]).")
    data_path = "$archive_root/$casename/ocn/hist"

    case_output_dir = "$output_dir/$casename"
    mkpath(case_output_dir)

    if models[i] == "POP2"
        middle_part = "pop.h"
    else
        middle_part = "EMOM.h0.mon"
    end

    for y = yrng[1]:yrng[2]

        println("Doing year: ", y, "\r")
        input_files = format("$data_path/$casename.$middle_part.{:04d}-{{01..12}}.nc", y)
        output_file = format("$case_output_dir/$casename.ocn.{:04d}.nc", y)        

        pleaseRun(`bash -c "ncra -O -v $varlist $input_files $output_file"`)

    end
end

println("Done.")
