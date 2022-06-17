addDiagnoseEntry(DiagnoseEntry(
        "ocn",
        "ocn-REGRID",
        function (cfg, params)
            output_dir = joinpath(cfg["extra_data_dir"], "ocn-REGRID")
            output_files = []
            for y = cfg["diag_beg_year"]:cfg["diag_end_year"], m=1:12
                date_str = format("{:04d}-{:02d}", y, m)
                push!(output_files, joinpath(output_dir, "$(cfg["casename"]).ocnsfc_rg.$(date_str).nc"))
            end

            return output_files 
        end,
        function (cfg, params)

            cmds = []

            output_dir = joinpath(cfg["extra_data_dir"], "ocn-REGRID")
            push!(cmds, `mkdir -p $output_dir`)

            for y = cfg["diag_beg_year"]:cfg["diag_end_year"], m=1:12
                date_str = format("{:04d}-{:02d}", y, m)

                if ! cfg["pop2"]
                    old_file  = joinpath(cfg["hist_dir_ocn"],  "$(cfg["casename"]).EMOM.h0.mon.$(date_str).nc")
                    Nx = "Nx"
                    Ny = "Ny"
                    Nz = "Nz"
                    extra_ncap2 = "HMXL2D=array(0.0,0.0,/\$time,\$$Ny,\$$Nx/); HMXL2D(0,:,:)=HMXL(0,0,:,:);"
                else
                    old_file  = joinpath(cfg["hist_dir_ocn"],  "$(cfg["casename"]).pop.h.$(date_str).nc")
                    Nx = "nlon"
                    Ny = "nlat"
                    Nz = "z_t"
                    extra_ncap2 = "HMXL=HMXL/100.0;" # Convert from centimeter to meter
                end


                new_file1 = joinpath(output_dir, "$(cfg["casename"]).ocnsfc.$(date_str).nc")
                new_file2 = joinpath(output_dir, "$(cfg["casename"]).ocnsfc_rg.$(date_str).nc")
               

                push!(cmds, `ncap2 -h -O -v 
                            -s "SST=array(0.0,0.0,/\$time,\$$Ny,\$$Nx/);  SST(0,:,:)=TEMP(0,0, :, :);"
                            -s $extra_ncap2
                            $old_file $new_file1`
                )

                if ! cfg["pop2"]
                    push!(cmds, `ncrename -v HMXL2D,HMXL $new_file1`)
                end
       
                if cfg["pop2"]
                    push!(cmds, `ncrename -d nlat,Ny -d nlon,Nx -d z_t,Nz $new_file1`)
                end

                push!(cmds, `ncremap -R '--rgr lat_nm_in=Ny --rgr lon_nm_in=Nx' -m $(cfg["remap-file-nn-ocn2atm"]) $new_file1 $new_file2`) 
            end

            return cmds

        end
    )
)


addDiagnoseEntry(DiagnoseEntry(
        "ocn",
        "ocn-MAP_MEANANOM",
        function(cfg, params)
            output_files = []
            for varname in params
                push!(output_files, joinpath(cfg["diagcase_data_dir"], "ocn_analysis_mean_anomaly_$(varname).nc"))
            end
            return output_files
        end,
        function(cfg, params)
            cmds = []
            for varname in params
                output_file = joinpath(cfg["diagcase_data_dir"], "ocn_analysis_mean_anomaly_$(varname).nc")
                push!(cmds, `julia $(cfg["lib_dir"])/mean_anomaly.jl
                     --data-file-prefix "$(cfg["extra_data_dir"])/ocn-REGRID/$(cfg["casename"]).ocnsfc_rg."
                     --data-file-timestamp-form YEAR_MONTH
                     --domain-file $(cfg["domain_atm"])
                     --output-file $output_file
                     --beg-year $(cfg["diag_beg_year"])
                     --end-year $(cfg["diag_end_year"])
                     --varname  $(varname)
                     --dims     XYT
                `)
            end
            return cmds
        end 
    )
)
