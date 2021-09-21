#!/bin/bash

echo "Diag FOM"

if [ ! -f no_diag_FOM ]; then

    # Diagnose ocn in displaced pole grid
    echo "Diagnose ocn..."
    julia $analysis_path/SST_correlation.jl --data-file=$ocn_outputfile --domain-file=$ocn_domain --SST=T


    # Transform processed data
    julia $coordtrans_scripts_path/transform_data.jl --s-file=$ocn_outputfile --d-file=$ocn_trans_outputfile_anomalies --w-file=$wgt_file --vars=SSTA --x-dim=Nx --y-dim=Ny --z-dim=Nz --t-dim=time 
    julia $coordtrans_scripts_path/transform_data.jl --s-file=$ocn_outputfile --d-file=$ocn_trans_outputfile_mstat --w-file=$wgt_file --vars=SSTAYYC,SSTAVAR --x-dim=Nx --y-dim=Ny --z-dim=Nz --t-dim=months


    julia $analysis_path/PDO.jl --data-file-SSTA=$ocn_trans_outputfile_anomalies --domain-file=$atm_domain --EOF-file-PDO=$PDO_file

fi
