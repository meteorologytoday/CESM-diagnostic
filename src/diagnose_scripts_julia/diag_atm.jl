addDiagnoseEntry(DiagnoseEntry(
        "atm",
        "atm-PRECIP",
        function (cfg, params)
            output_dir = joinpath(cfg["extra_data_dir"], "PRECIP")
            output_files = []
            for y = cfg["diag_beg_year"]:cfg["diag_end_year"], m=1:12
                date_str = format("{:04d}-{:02d}", y, m)
                push!(output_files, joinpath(output_dir, "$(cfg["casename"]).cam_extra1.$(date_str).nc"))
            end

            return output_files 
        end,
        function (cfg, params)
            
            cmds = []

            output_dir = joinpath(cfg["extra_data_dir"], "PRECIP")
            push!(cmds, `mkdir -p $output_dir`)
            
            for y = cfg["diag_beg_year"]:cfg["diag_end_year"], m=1:12
             
                date_str = format("{:04d}-{:02d}", y, m)

                old_file = joinpath(cfg["hist_dir_atm"], "$(cfg["casename"]).cam.h0.$(date_str).nc")
                new_file1 = joinpath(output_dir, "$(cfg["casename"]).cam_extra1.$(date_str).nc")
                if !isfile(new_file1) || cfg["overwrite"]
                    println("Generating file: $(new_file1)")
                    push!(cmds, `ncap2 -h -O -v -s 'PREC_TOTAL=PRECC+PRECL;' $old_file $new_file1`)
                end

            end

            return cmds
 
        end 
    )
)

addDiagnoseEntry(DiagnoseEntry(
        "atm",
        "atm-HEAT_TRANSPORT",
        function (cfg, params)
            return joinpath(cfg["diagcase_data_dir"], "atm_analysis_AHT.nc")
        end,
        function(cfg, params)
            output_file = joinpath(cfg["diagcase_data_dir"], "atm_analysis_AHT.nc")
            return `julia $(cfg["lib_dir"])/atm_heat_transport.jl
                  --data-file-prefix "$(cfg["hist_dir_atm"])/$(cfg["casename"]).cam.h0."
                  --data-file-timestamp-form YEAR_MONTH
                  --domain-file $(cfg["domain_atm"])
                  --output-file $output_file
                  --beg-year $(cfg["diag_beg_year"])
                  --end-year $(cfg["diag_end_year"])
            `
        end
    )
)

addDiagnoseEntry(DiagnoseEntry(
        "atm",
        "atm-CLIMMODE_PDO",
        function(cfg, params)
            return joinpath(cfg["diagcase_data_dir"], "atm_analysis_PDO.nc")
        end,
        function(cfg, params)
            output_file = joinpath(cfg["diagcase_data_dir"], "atm_analysis_PDO.nc")
            return `julia $(cfg["lib_dir"])/EOFs/PDO.jl
                    --data-file-prefix "$(cfg["hist_dir_atm"])/$(cfg["casename"]).cam.h0."
                    --data-file-timestamp-form YEAR_MONTH
                    --domain-file $(domain_atm)
                    --output-file $output_file
                    --beg-year $(cfg["diag_beg_year"])
                    --end-year $(cfg["diag_end_year"])
                    --SST-varname SST
                    --dims XYT
                    --sparsity 1
            `
        end,
    )
)

addDiagnoseEntry(DiagnoseEntry(
        "atm",
        "atm-MAP_MEANANOM",
        function(cfg, params)
            output_files = []
            for varname in params
                push!(output_files, joinpath(cfg["diagcase_data_dir"], "atm_analysis_mean_anomaly_$(varname).nc"))
            end
            return output_files
        end,
        function(cfg, params)
            cmds = []
            for varname in params
                output_file = joinpath(cfg["diagcase_data_dir"], "atm_analysis_mean_anomaly_$(varname).nc")

                if varname == "PREC_TOTAL"
                    data_file_prefix = "$(cfg["extra_data_dir"])/PRECIP/$(cfg["casename"]).cam_extra1."
                else
                    data_file_prefix = "$(cfg["hist_dir_atm"])/$(cfg["casename"]).cam.h0."
                end

                push!(cmds, `julia $(cfg["lib_dir"])/mean_anomaly.jl
                     --data-file-prefix $data_file_prefix
                     --data-file-timestamp-form YEAR_MONTH
                     --domain-file $(cfg["domain_atm"])
                     --output-file $output_file
                     --beg-year $(cfg["diag_beg_year"])
                    --end-year $(cfg["diag_end_year"])
                    --varname  $(varname)
                    --dims     XYT
                    --output-monthly-anomalies false
                `)
            end
            return cmds
        end 
    )
)
