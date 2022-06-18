include("../CESM-diagnostic/src/misc/RunCommands.jl")

using .RunCommands
using Formatting

include("setup.jl")


gonna_do = keys(cases)

#gonna_do = ["qco2_SOM", "qco2_MLM", "qco2_EMOM", "qco"]

year_skip = 10
sfc_layers = 1

varlist = join(["TEMP", "SALT",], ",")

# Making annual average
for (casename, caseinfo) in cases

    if ! ( casename in gonna_do )
        println("Not gonna do $casename.")
        continue
    end

    println("Doing casename: $casename")

    output_dir_case = "$output_dir/$casename/ocn"
    mkpath(output_dir_case)


    yrng = caseinfo["yrng"]
    println("Doing year range: $(yrng[1]) to $(yrng[2]). year_skip = $year_skip")
    data_path = "$archive_root/$casename/ocn/hist"

    if caseinfo["model"] == "POP2"
        middle_part = "pop.h"
    else
        middle_part = "EMOM.h0.mon"
    end


    mkpath("tmp_ocn")
    for y = yrng[1]:year_skip:yrng[2]

        println("Doing year: ", y, "\r")
        input_file  = format("$data_path/$casename.$middle_part.{{{:04d}..{:04d}}}-{{01..12}}.nc", y, y + year_skip - 1)
        output_file = format("$output_dir_case/$casename.ocn.sfc.{:04d}.nc", y)        
        tmp_avg_file = format("tmp_ocn/tmp_{:04d}.nc", y)
            

        if isfile(output_file)
            println("File `$output_file` exists. Skip this.")
        else

            if caseinfo["model"] == "POP2"
                output_file2 = format("$output_dir_case/$casename.ocn.total.{:04d}.nc", y)

                pleaseRun(`bash -c "ncra -F -O -v $(varlist),dz -d z_t,1,$sfc_layers $input_file $tmp_avg_file"`)
                pleaseRun(`ncap2 -O -s "TEMP=TEMP/100.0;" $tmp_avg_file $tmp_avg_file`)
                pleaseRun(`bash -c "ncwa -F -O -y ttl -w dz -a z_t -d z_t,1,$sfc_layers  -v $varlist $tmp_avg_file $output_file"`)
                pleaseRun(`bash -c "ncwa    -O -y ttl -w dz -a z_t                       -v $varlist $tmp_avg_file $output_file2"`)
                #pleaseRun(`ncap2 -O -s "TEMP=TEMP/100.0;" $output_file $output_file`)
                #pleaseRun(`ncap2 -O -s "TEMP=TEMP/100.0;" $output_file2 $output_file2`)
            else
                pleaseRun(`bash -c "ncra -F -O -v $(varlist),dz_cT -d Nz,1,$sfc_layers $input_file $tmp_avg_file"`)
                pleaseRun(`bash -c "ncwa    -O -a N1 -v TEMP,SALT,dz_cT $tmp_avg_file $output_file"`)
                pleaseRun(`bash -c "ncwa -F -O -y ttl -w dz_cT -a Nz -d Nz,1,$sfc_layers -v $varlist $output_file $output_file"`)
            end

        end
        
    end
    rm("tmp_ocn"; recursive=true)
end

println("Done.")
