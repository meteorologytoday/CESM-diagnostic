using ArgParse
using Formatting
using JSON,TOML
using DataStructures

include("runCmd.jl")
include("tools.jl")

s = ArgParseSettings()
@add_arg_table s begin

    "--diag-file"
        help = "The TOML file containing the information to diagnose."
        arg_type = String
        required = true

    "--diag-overwrite"
        action = :store_true
 
end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)

include("analysis_dict.jl")

cfg = TOML.parsefile(parsed["diag-file"]) |> DataStructures.OrderedDict
println("Loaded diagnose configuration file ", parsed["diag-file"])
JSON.print(cfg, 4)

result_dir = "result"
diag_data_dir = joinpath(result_dir, cfg["diag-label"])
mkpath(result_dir)
mkpath(diag_data_dir)

lib_dir=joinpath(@__DIR__, "lib")
    
domain_atm = cfg["domains"]["atm"] 
domain_ocn = cfg["domains"]["ocn"]
domain_ice = cfg["domains"]["ice"]


for (diagcase_name, diagcase) in cfg["diagcases"]

    println("Diagcase detail: ")
    JSON.print(diagcase, 4)

    extra_data_dir = joinpath(result_dir, "extra_data", diagcase["casename"])
    diagcase_data_dir = joinpath(diag_data_dir, diagcase["casename"])

    mkpath(extra_data_dir)
    mkpath(diagcase_data_dir)

    hist_dir_atm = joinpath(cfg["archive-root"], diagcase["casename"], "atm", "hist")
    hist_dir_ice = joinpath(cfg["archive-root"], diagcase["casename"], "ice", "hist")

    casename = diagcase["casename"]
    diag_beg_year, diag_end_year = diagcase["year-rng"]


    if cfg["diagnose"]["atm"]
        
        println("Diagnosing atm...")
    
        pleaseRun(`julia $(@__DIR__)/make_extra_data_atm.jl
            --casename   $(casename)
            --input-dir  $(hist_dir_atm)
            --output-dir $(extra_data_dir)
            --year-rng   $(diag_beg_year) $(diag_end_year)
            --domain-file $(domain_atm)
        `)


        # Meridional averaged varables
        #for varname in ["U", "T", "VU", "VT", "VQ"]
        for varname in ["U", "T"]
            output_file = "$(diagcase_data_dir)/atm_analysis_mean_anomaly_$(varname)_zm.nc"
            if !isfile(output_file) || parsed["diag-overwrite"]
                pleaseRun(`julia $(lib_dir)/mean_anomaly.jl
                     --data-file-prefix "$(extra_data_dir)/$(casename).cam_extra2_zmean."
                     --data-file-timestamp-form YEAR_MONTH
                     --domain-file $(domain_atm)
                     --output-file $output_file
                     --beg-year $diag_beg_year
                     --end-year $diag_end_year
                     --varname  $(varname)
                     --dims     YZT
                `)
            end
        end
 
            
        if !isfile(output_file) || parsed["diag-overwrite"]
            output_file = "$(diagcase_data_dir)/atm_analysis_mean_anomaly_streamfunction.nc"
            pleaseRun(`julia $(lib_dir)/mean_anomaly.jl
                 --data-file-prefix "$(extra_data_dir)/$(casename).cam_extra3_streamfunction."
                 --data-file-timestamp-form YEAR_MONTH
                 --domain-file $(domain_atm)
                 --output-file $output_file
                 --beg-year $diag_beg_year
                 --end-year $diag_end_year
                 --varname  psi
                 --dims     YZ
            `)
        end

        begin
            varname = "PREC_TOTAL" 
            output_file = "$(diagcase_data_dir)/atm_analysis_mean_anomaly_$(varname).nc"
            output_file_zm = "$(diagcase_data_dir)/atm_analysis_mean_anomaly_$(varname)_zm.nc"

            if !isfile(output_file) || parsed["diag-overwrite"]
                pleaseRun(`julia $(lib_dir)/mean_anomaly.jl
                     --data-file-prefix "$(extra_data_dir)/$(casename).cam_extra1."
                     --data-file-timestamp-form YEAR_MONTH
                     --domain-file $(domain_atm)
                     --output-file $output_file
                     --beg-year $diag_beg_year
                     --end-year $diag_end_year
                     --varname  $(varname)
                     --dims     XYT
                `)

                pleaseRun(`ncwa -h -O -a Nx $output_file $output_file_zm`)
            end
        end

        for varname in ["TREFHT", "SST", "TAUX", "PSL", "ICEFRAC", "LHFLX", "SWCF", "LWCF"]
            output_file = "$(diagcase_data_dir)/atm_analysis_mean_anomaly_$(varname).nc"
            output_file_zm = "$(diagcase_data_dir)/atm_analysis_mean_anomaly_$(varname)_zm.nc"

            if !isfile(output_file) || parsed["diag-overwrite"]
                pleaseRun(`julia $(lib_dir)/mean_anomaly.jl
                     --data-file-prefix "$(hist_dir_atm)/$(casename).cam.h0."
                     --data-file-timestamp-form YEAR_MONTH
                     --domain-file $(domain_atm)
                     --output-file $output_file
                     --beg-year $diag_beg_year
                     --end-year $diag_end_year
                     --varname  $(varname)
                     --dims     XYT
                `)

                pleaseRun(`ncwa -h -O -a Nx $output_file $output_file_zm`)
            end

        end
            
        if !isfile(output_file) || parsed["diag-overwrite"]
            pleaseRun(`julia $(lib_dir)/atm_heat_transport.jl
                --data-file-prefix "$(hist_dir_atm)/$(casename).cam.h0."
                --data-file-timestamp-form YEAR_MONTH
                --domain-file $(domain_atm)
                --output-file $output_file
                --beg-year $diag_beg_year
                --end-year $diag_end_year
            `)
        end 
    # Atmosphere tropical precipitation asymmetry index
    # julia $script_analysis_dir/atm_PAI.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis31 --beg-year=$diag_beg_year --end-year=$diag_end_year

    # Downstream data. No need to specify --beg-year --end-year
    #julia $script_analysis_dir/AO.jl --data-file=$atm_analysis1 --domain-file=$atm_domain --output-file=$atm_analysis5 --sparsity=$PCA_sparsity



    end


    if cfg["diagnose"]["ice"]
        pleaseRun(`julia $(@__DIR__)/make_extra_data_ice.jl
            --casename   $(casename)
            --input-dir  $(hist_dir_ice)
            --output-dir $(extra_data_dir)
            --year-rng   $(diag_beg_year) $(diag_end_year)
            --domain-file $(domain_ice)
            --remap-file-nn $(cfg["remap-files"]["ice2atm"]["nn"])
        `)



    end
end
