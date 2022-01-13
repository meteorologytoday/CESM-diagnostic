#!/bin/bash

plot_path=$diagnose_scripts_path/plot


# atm
#python3 $plot_path/plot_SST.py --data-file=$atm_outputfile --domain-file=$atm_domain --output-dir=$diagnose_output_dir --casename=$casename

# ocn
#python3 $plot_path/plot_ocean_diagnose.py --data-file-SSTAYYC=$ocn_trans_outputfile --data-file-SSTAVAR=$ocn_trans_outputfile --domain-file=$atm_domain --output-dir=$diagnose_output_dir --casename=$casename

# ice
python3 $plot_path/plot_mc_timeseries.py --input-dir=$nc_output_dir/../ --output-dir=$diagnose_output_dir/$casename --res=$res --casenames=$casename --data-file=$(basename $ice_analysis1) --varname=total_ice_volume --ylabel="Ice volume [m^3] "

# General
#python3 $plot_path/plot_climate_indices.py --data-file-PDO=$ocn_trans_outputfile --output-dir=$diagnose_output_dir --data-file-AO=$atm_outputfile_anomalies --casename=$casename
#python3 $plot_path/plot_mc_climate_indices.py --input-dir=$nc_output_dir/../ --output-dir=$diagnose_output_dir/$casename --res=$res --casenames=$casename --data-file=$(basename $ocn_trans_outputfile) --varname=PDO --normalize=no

