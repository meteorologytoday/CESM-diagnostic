addPreprocessEntry(PreprocessEntry(
        "ATM-PRECIP",
        function (cfg)
            
            output_dir = joinpath(cfg["extra_data_dir"], "PRECIP")
            mkpath(output_dir)
            for y = cfg["beg-year"][1]:cfg["end-year"][2], m=1:12
             
                date_str = format("{:04d}-{:02d}", y, m)

                old_file = joinpath(cfg["hist_dir_atm"], "$(cfg["casename"]).cam.h0.$(date_str).nc")
                new_file1 = joinpath(output_dir, "$(cfg["casename"]).cam_extra1.$(date_str).nc")
                if !isfile(new_file1) || cfg["overwrite"]
                    println("Generating file: $(new_file1)")
                    pleaseRun(`ncap2 -h -O -v -s 'PREC_TOTAL=PRECC+PRECL;' $old_file $new_file1`)
                end

            end
 
        end 
    )
)
