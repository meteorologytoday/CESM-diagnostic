#!/bin/bash


if [ ! -f flag_nodiag_atm ] ; then

    echo "Diagnose atm..."
    #julia $script_analysis_dir/atm_anomalies.jl --data-file=$atm_concat --domain-file=$atm_domain --output-file=$atm_analysis1
    #julia $script_analysis_dir/atm_temperature.jl --data-file=$atm_concat --domain-file=$atm_domain --output-file=$atm_analysis2
    #julia $script_analysis_dir/AO.jl --data-file-PSLA=$atm_analysis1 --domain-file=$atm_domain --EOF-file-AO=$AO_file
    julia $script_analysis_dir/implied_atm_energy_transport.jl --data-file=$atm_concat --domain-file=$atm_domain --output-file=$atm_analysis3
fi

if [ ! -f flag_nodiag_ocn ] ; then

    echo "Diagnose ocn..."
    julia $script_analysis_dir/SST_correlation.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --SST=T
    julia $script_analysis_dir/PDO.jl --data-file-SSTA=$ocn_concat_rg --domain-file=$atm_domain --EOF-file-PDO=$PDO_file
    julia $script_analysis_dir/EN34.jl --data-file-SSTA=$ocn_concat_rg --domain-file=$atm_domain 

fi

if [ ! -f flag_nodiag_ice ] ; then

    echo "Diagnose ice..."
    julia $script_analysis_dir/ice.jl --data-file=$ice_concat_rg --domain-file=$atm_domain --output-file=$ice_analysis1

fi
