#!/bin/bash

lopts=(
    casename
    output-name
    sim-data-dir
    concat-data-dir
    diag-data-dir
    graph-data-dir
    atm-domain
    ocn-domain
    ice-domain
    diag-beg-year
    diag-end-year
    PDO-file
    AO-file
    PCA-sparsity
    stop-after-phase1
    wgt-dir
)

options=$(getopt -o '' --long $(printf "%s:," "${lopts[@]}") -- "$@")
[ $? -eq 0 ] || { 
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"


while true; do
    for lopt in "${lopts[@]}"; do
        eval "if [ \"\$1\" == \"--$lopt\" ]; then shift; export ${lopt//-/_}=\"\$1\"; shift; break; fi"
    done

    if [ "$1" == -- ]; then
        shift;
        break;
    fi
done

echo "Received parameters: "
for lopt in "${lopts[@]}"; do
    llopt=${lopt//-/_}
    eval "echo \"- $llopt=\$$llopt\""
done

export diag_beg_year=$(printf "%04d" $diag_beg_year)
export diag_end_year=$(printf "%04d" $diag_end_year)

export diag_year_stamp=$(printf "%s-%s" $diag_beg_year $diag_end_year)

export PDO_file=PDO_EOFs_fv45.nc
export AO_file=AO_EOFs_fv45.nc


export wdir=`pwd`
export script_root_dir=$( dirname "$(realpath $0)" )
export script_analysis_dir=$script_root_dir/analysis
export script_coordtrans_dir=$script_root_dir/../CoordTrans
export script_plot_dir=$script_root_dir/plot


echo "Phase 0: Define variables"

export casename=$casename

# directories
export concat_dir=$concat_data_dir/$casename
export diag_dir=$diag_data_dir/$output_name
export graph_dir=$graph_data_dir/$output_name
export sim_dir=$sim_data_dir/$casename
export atm_hist_dir=$sim_dir/atm/hist
export ocn_hist_dir=$sim_dir/ocn/hist
export ice_hist_dir=$sim_dir/ice/hist

# filenames
export atm_concat=$concat_dir/atm_concat.nc
export atm_prec=$concat_dir/atm_prec.nc
export ocn_concat=$concat_dir/ocn_concat.nc
export ice_concat=$concat_dir/ice_concat.nc

export ice_concat_rg=$concat_dir/ice_concat_rg.nc
export ocn_concat_rg=$concat_dir/ocn_concat_rg.nc

export atm_analysis1=$diag_dir/atm_analysis1.nc
export atm_analysis2=$diag_dir/atm_analysis2.nc
export atm_analysis2a=$diag_dir/atm_analysis2a.nc
export atm_analysis3=$diag_dir/atm_analysis3_energy.nc
export atm_analysis4=$diag_dir/atm_analysis4_precip.nc
export atm_analysis4a=$diag_dir/atm_analysis4a_precip.nc
export atm_analysis5=$diag_dir/atm_analysis5_AO.nc
export atm_analysis6=$diag_dir/atm_analysis6_icefrac.nc
export atm_analysis6a=$diag_dir/atm_analysis6a_icefrac.nc
export atm_analysis7=$diag_dir/atm_analysis7.nc
export atm_analysis8=$diag_dir/atm_analysis8_PDO.nc
export atm_analysis9=$diag_dir/atm_analysis9_EN34.nc
export atm_analysis10=$diag_dir/atm_analysis10_T.nc
export atm_analysis11=$diag_dir/atm_analysis11_U.nc
export atm_analysis12=$diag_dir/atm_analysis12_psi.nc
export atm_analysis12a=$diag_dir/atm_analysis12a_psi.nc
export atm_analysis13=$diag_dir/atm_analysis13_T.nc
export atm_analysis14=$diag_dir/atm_analysis14_VU.nc
export atm_analysis15=$diag_dir/atm_analysis15_VT.nc
export atm_analysis16=$diag_dir/atm_analysis16_VQ.nc
export atm_analysis17=$diag_dir/atm_analysis17_TAUX.nc
export atm_analysis18=$diag_dir/atm_analysis18_hadleycell.nc
export atm_analysis19=$diag_dir/atm_analysis19_LHFLX.nc
export atm_analysis20=$diag_dir/atm_analysis20_SWCF.nc
export atm_analysis21=$diag_dir/atm_analysis21_LWCF.nc
export atm_analysis22=$diag_dir/atm_analysis22_ts_zm_PREC.nc
export atm_analysis31=$diag_dir/atm_analysis31_PAI.nc




export ocn_analysis1_rg=$diag_dir/ocn_analysis1_SST_anomalies_rg.nc
export ocn_analysis1a_rg=$diag_dir/ocn_analysis1a_SST_anomalies_rg.nc
export ocn_analysis2_rg=$diag_dir/ocn_analysis2_rg_PDO.nc
export ocn_analysis3_rg=$diag_dir/ocn_analysis3_rg_MLD.nc
export ocn_analysis3a_rg=$diag_dir/ocn_analysis3a_rg_MLD.nc
export ocn_analysis4_rg=$diag_dir/ocn_analysis4_rg_dTdt_ent.nc
export ocn_analysis4a_rg=$diag_dir/ocn_analysis4a_rg_dTdt_ent.nc
export ocn_analysis5_rg=$diag_dir/ocn_analysis5_rg_T_hadvs.nc
export ocn_analysis5a_rg=$diag_dir/ocn_analysis5a_rg_T_hadvs.nc
export ocn_analysis6_rg=$diag_dir/ocn_analysis6_rg_T_vadvs.nc
export ocn_analysis6a_rg=$diag_dir/ocn_analysis6a_rg_T_vadvs.nc
export ocn_analysis7_rg=$diag_dir/ocn_analysis7_rg_swflx.nc
export ocn_analysis7a_rg=$diag_dir/ocn_analysis7a_rg_swflx.nc
export ocn_analysis8_rg=$diag_dir/ocn_analysis8_rg_nswflx.nc
export ocn_analysis8a_rg=$diag_dir/ocn_analysis8a_rg_nswflx.nc
export ocn_analysis9_rg=$diag_dir/ocn_analysis9_rg_oiet.nc
export ocn_analysis9a_rg=$diag_dir/ocn_analysis9a_rg_oiet.nc
export ocn_analysis9b_rg=$diag_dir/ocn_analysis9b_rg_oiet_avg.nc
export ocn_analysis10_rg=$diag_dir/ocn_analysis10_rg.nc
export ocn_analysis10a_rg=$diag_dir/ocn_analysis10a_rg.nc
export ocn_analysis11_rg=$diag_dir/ocn_analysis11_rg_EN34.nc
export ocn_analysis12_rg=$diag_dir/ocn_analysis12_rg_OHT.nc
export ocn_analysis13_rg=$diag_dir/ocn_analysis13_rg_IOET.nc
export ocn_analysis14=$diag_dir/ocn_analysis14_TEMP_SALT.nc
export ocn_analysis15=$diag_dir/ocn_analysis15_FLUX_DIV.nc
export ocn_analysis16_rg=$diag_dir/ocn_analysis16_rg_OST.nc


export ocn_mstat_rg=$diag_dir/ocn_mstat_rg.nc


export ice_analysis1=$diag_dir/ice_analysis01_volume_area.nc
export ice_analysis2=$diag_dir/ice_analysis02_vice.nc
export ice_analysis2a_rg=$diag_dir/ice_analysis02a_rg_vice.nc
export ice_analysis3=$diag_dir/ice_analysis03_aice.nc
export ice_analysis3a_rg=$diag_dir/ice_analysis03a_rg_aice.nc

for dir_path in $graph_dir $diag_dir $concat_dir ; do

    echo "Checking path: $dir_path"
    mkdir -p $dir_path

done


echo "Phase 1: Generateing weight data, concat and transform data"
begin_t=$SECONDS
if [ ! -f flag_noconcat ]; then


    echo "Doing case: ${casename}"
    

    # Doing stuff...
    mkdir -p $diag_dir
    $script_root_dir/concat_files_atm.sh 
    $script_root_dir/concat_files_ocn.sh 
    $script_root_dir/concat_files_ice.sh 


    # Pull out `lev` of atm files

    if [ ! -f "$diag_dir/atm_lev.nc" ]; then
        ncap2 -v -O -s "lev=lev;" $atm_hist_dir/$casename.cam.h0.$diag_beg_year-01.nc $diag_dir/atm_lev.nc
    fi

    if [ ! -f "$diag_dir/atm_ilev.nc" ]; then
        ncap2 -v -O -s "ilev=ilev;" $atm_hist_dir/$casename.cam.h0.$diag_beg_year-01.nc $diag_dir/atm_ilev.nc
    fi

fi
printf "Phase 1 takes %d seconds\n" $(( $SECONDS - $begin_t ))

wait

if [ ! -z "$stop_after_phase1" ] ; then
    echo "### --stop-after-phase1 is nonempty. Exit now. "
    exit
fi


echo "Phase 2: Doing calculation of diagnose"
begin_t=$SECONDS
echo "Doing case: ${casename}"

if [ -f flag_diag_fornow ] ; then
    
    julia $script_analysis_dir/ocean_salt_transport.jl --data-file-prefix="$ocn_hist_dir/$casename.ocn.h.monthly." --data-file-timestamp-form=YEAR_MONTH --domain-file=$ocn_domain --output-file=$ocn_analysis16_rg --beg-year=$diag_beg_year --end-year=$diag_end_year
    
    # Atmosphere tropical precipitation asymmetry index
    #julia $script_analysis_dir/atm_PAI.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis31 --beg-year=$diag_beg_year --end-year=$diag_end_year
 
   #julia $script_analysis_dir/atm_heat_transport.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis3 --beg-year=$diag_beg_year --end-year=$diag_end_year


    
    #julia $script_analysis_dir/timeseries_zonal_mean.jl --data-file-prefix="$concat_dir/$casename.cam_extra.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis22 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=PREC_TOTAL --dims=XYT 
#    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis20 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=SWCF --dims=XYT
#    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis21 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=LWCF --dims=XYT


#    julia $script_analysis_dir/ocean_heat_transport.jl --data-file-prefix="$ocn_hist_dir/$casename.ocn.h.monthly." --data-file-timestamp-form=YEAR_MONTH --domain-file=$ocn_domain --output-file=$ocn_analysis12_rg --beg-year=$diag_beg_year --end-year=$diag_end_year
    
    #julia $script_analysis_dir/atm_hadleycells_strength.jl --data-file-prefix="$concat_dir/$casename.cam_extra3_streamfunction.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --ilev-file=$diag_dir/atm_ilev.nc --output-file=$atm_analysis18 --varname=psi --beg-year=$diag_beg_year --end-year=$diag_end_year
 #   julia $script_analysis_dir/atm_heat_transport.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis3 --beg-year=$diag_beg_year --end-year=$diag_end_year
 
     #julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis19 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=LHFLX --dims=XYT
    #julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis20 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=SWCF --dims=XYT
    #julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis21 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=LWCF --dims=XYT


fi

if [ -f flag_diag_all ] || [ -f flag_diag_atm ] ; then

    echo "Diagnose atm..."

    # Meridional averaged U
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra2_zonal_mean.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis11 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=U --dims=YZT

    # Meridional averaged T
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra2_zonal_mean.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis13 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=T --dims=YZT

    # Meridional averaged VU
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra2_zonal_mean.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis14 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=VU --dims=YZT

    # Meridional averaged VT
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra2_zonal_mean.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis15 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=VT --dims=YZT

    # Meridional averaged VQ
    # julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra2_zonal_mean.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis16 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=VQ --dims=YZT

    # Streamfunction
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra3_streamfunction.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis12 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=psi --dims=YZ
    ncwa -h -O -a Nx $atm_analysis12 $atm_analysis12a

    
    # Find strength of Hadley cells
    julia $script_analysis_dir/atm_hadleycells_strength.jl --data-file-prefix="$concat_dir/$casename.cam_extra3_streamfunction.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --ilev-file=$diag_dir/atm_ilev.nc --output-file=$atm_analysis18 --varname=psi --beg-year=$diag_beg_year --end-year=$diag_end_year


    # Surface temperature (TREFHT) monthly mean and anomaly
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis2 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=TREFHT --dims=XYT

    ncwa -h -O -a Nx $atm_analysis2 $atm_analysis2a

    # Total precipitation
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cam_extra.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis4 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=PREC_TOTAL --dims=XYT 
    ncwa -h -O -a Nx $atm_analysis4 $atm_analysis4a

    # Precipitation timeseries
    julia $script_analysis_dir/timeseries_zonal_mean.jl --data-file-prefix="$concat_dir/$casename.cam_extra.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis22 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=PREC_TOTAL --dims=XYT 


    # TAUX
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis17 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=TAUX --dims=XYT 

    # Sea-level Pressure monthly mean and anomaly
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis1 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=PSL --output-monthly-anomalies --dims=XYT

    # Sea-ice monthly mean and anomaly
    #julia $script_analysis_dir/mean_anomaly.jl --data-file=$atm_concat --domain-file=$atm_domain --output-file=$atm_analysis6 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=ICEFRAC
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis6 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=ICEFRAC --dims=XYT
    ncwa -h -O -a Nx $atm_analysis6 $atm_analysis6a
    
    # Global Ice volume / fraction / area
    # julia $script_analysis_dir/atm_ice.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$ice_analysis1 --beg-year=$diag_beg_year --end-year=$diag_end_year

    # Global Average Temperature analysis
    julia $script_analysis_dir/atm_temperature.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis7 --beg-year=$diag_beg_year --end-year=$diag_end_year
    

    # IAET : Implied Atmospheric Energy Transport
    #julia $script_analysis_dir/implied_atm_energy_transport.jl --data-file=$atm_concat --domain-file=$atm_domain --output-file=$atm_analysis3 --beg-year=$diag_beg_year --end-year=$diag_end_year
    #julia $script_analysis_dir/implied_atm_energy_transport.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis3 --beg-year=$diag_beg_year --end-year=$diag_end_year
    
    # Atmopshere heat transport
    julia $script_analysis_dir/atm_heat_transport.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis3 --beg-year=$diag_beg_year --end-year=$diag_end_year
    
    # Atmosphere tropical precipitation asymmetry index
    julia $script_analysis_dir/atm_PAI.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis31 --beg-year=$diag_beg_year --end-year=$diag_end_year

    # Downstream data. No need to specify --beg-year --end-year
    #julia $script_analysis_dir/AO.jl --data-file=$atm_analysis1 --domain-file=$atm_domain --output-file=$atm_analysis5 --sparsity=$PCA_sparsity


    # Cloud analysis : LHFLX, SWCF, LWCF
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis19 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=LHFLX --dims=XYT
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis20 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=SWCF --dims=XYT
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$atm_hist_dir/$casename.cam.h0." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$atm_analysis21 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=LWCF --dims=XYT



fi

if [ -f flag_diag_all ] || [ -f flag_diag_ocn ] ; then

    echo "Diagnose ocn..."
    
#    julia $script_analysis_dir/implied_ocn_energy_transport.jl --data-file-prefix="$concat_dir/$casename.ocn_rg2.h.monthly." --data-file-timestamp-form=YEAR --domain-file=$atm_domain --output-file=$ocn_analysis13_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --ESMF-wgt-file=$wgt_dir/wgt.conserve2nd.nc


    # Need to specify --beg-year --end-year
    #julia $script_analysis_dir/SST_correlation.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --SST=T_ML --beg-year=$diag_beg_year --end-year=$diag_end_year

    # Analysis total TEMP and SALT
    #julia $script_analysis_dir/ocn_total_TEMP_SALT.jl --data-file-prefix="$ocn_hist_dir/$casename.ocn.h.monthly." --data-file-timestamp-form=YEAR_MONTH --domain-file=$ocn_domain --output-file=$ocn_analysis14 --beg-year=$diag_beg_year --end-year=$diag_end_year
    

    ### Variability ###

    # SST
#    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.ocn_rg.h.monthly." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$ocn_analysis1_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=T_ML --output-monthly-anomalies --dims=XYT
#    ncwa -O -b -a Nx -B "mask==0" $ocn_analysis1_rg $ocn_analysis1a_rg


    # MLT
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.EMOM_rg.h0.mon." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$ocn_analysis3_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=HMXL --dims=XYT
    ncwa -O -b -a Nx -B "mask==0" $ocn_analysis3_rg $ocn_analysis3a_rg


    if [ ] ; then 
    # Ocean heat transport
    julia $script_analysis_dir/ocean_heat_transport.jl --data-file-prefix="$ocn_hist_dir/$casename.EMOM.h0.mon." --data-file-timestamp-form=YEAR_MONTH --domain-file=$ocn_domain --output-file=$ocn_analysis12_rg --beg-year=$diag_beg_year --end-year=$diag_end_year
    
    # Ocean salt transport
    julia $script_analysis_dir/ocean_salt_transport.jl --data-file-prefix="$ocn_hist_dir/$casename.ocn.h.monthly." --data-file-timestamp-form=YEAR_MONTH --domain-file=$ocn_domain --output-file=$ocn_analysis15_rg --beg-year=$diag_beg_year --end-year=$diag_end_year
 
    # Entrainment
#    julia $script_analysis_dir/mean_anomaly.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --output-file=$ocn_analysis4_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=dTdt_ent
#    ncwa -h -O -a months,Nx $ocn_analysis4_rg $ocn_analysis4a_rg
 
    # Horizontal advection
#    julia $script_analysis_dir/mean_anomaly.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --output-file=$ocn_analysis5_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=T_hadvs
#    ncwa -h -O -a months,Nx $ocn_analysis5_rg $ocn_analysis5a_rg
 
    # Solar surface flux
#    julia $script_analysis_dir/mean_anomaly.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --output-file=$ocn_analysis7_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=swflx
#    ncwa -h -O -a months,Nx $ocn_analysis7_rg $ocn_analysis7a_rg
  
    # Non-solar surface fluxes
#    julia $script_analysis_dir/mean_anomaly.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --output-file=$ocn_analysis8_rg --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=nswflx
#    ncwa -h -O -a months,Nx $ocn_analysis8_rg $ocn_analysis8a_rg
 
    # Ocean implied energy transport
#    julia $script_analysis_dir/implied_ocn_energy_transport.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --output-file=$ocn_analysis9_rg --beg-year=$diag_beg_year --end-year=$diag_end_year
#    julia $script_analysis_dir/mean_anomaly.jl --data-file=$ocn_analysis9_rg --domain-file=$atm_domain --output-file=$ocn_analysis9a_rg --beg-year=1 --end-year="$(( $diag_end_year - $diag_beg_year + 1 ))" --varname=IET_OCN 
#    ncwa -h -O -a months,Nx $ocn_analysis9a_rg $ocn_analysis9b_rg


    # Ocean energy analysis    
#    julia $script_analysis_dir/ocn_energy_analysis.jl --data-file=$ocn_concat_rg --domain-file=$atm_domain --output-file=$ocn_analysis10_rg --beg-year=$diag_beg_year --end-year=$diag_end_year
#    ncwa -h -O -a time $ocn_analysis10_rg $ocn_analysis10a_rg
    fi
    if [ ] ; then

    # Downstream data. No need to specify --beg-year --end-year
    julia $script_analysis_dir/PDO.jl --data-file=$ocn_analysis1_rg --domain-file=$atm_domain --output-file=$ocn_analysis2_rg
    julia $script_analysis_dir/EN34.jl --data-file=$ocn_analysis1_rg --domain-file=$atm_domain --output-file=$ocn_analysis11_rg --sparsity=$PCA_sparsity 

    fi
fi

if [ -f flag_diag_all ] || [ -f flag_diag_ice ] ; then

    echo "Diagnose ice..."
    # Need to specify --beg-year --end-year
    #julia $script_analysis_dir/ice.jl --data-file=$ice_concat_rg --domain-file=$atm_domain --output-file=$ice_analysis1 --beg-year=$diag_beg_year --end-year=$diag_end_year
    julia $script_analysis_dir/seaice.jl --data-file-prefix="$concat_dir/$casename.cice_extra.h." --data-file-timestamp-form=YEAR_MONTH --domain-file=$ocn_domain --output-file=$ice_analysis1 --beg-year=$diag_beg_year --end-year=$diag_end_year

    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cice_extra2_rg.h." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$ice_analysis2 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=vice --dims=XYT
    ncwa -h -O -a Nx $ice_analysis2 $ice_analysis2a_rg
    
    julia $script_analysis_dir/mean_anomaly.jl --data-file-prefix="$concat_dir/$casename.cice_extra2_rg.h." --data-file-timestamp-form=YEAR_MONTH --domain-file=$atm_domain --output-file=$ice_analysis3 --beg-year=$diag_beg_year --end-year=$diag_end_year --varname=vice --dims=XYT
    ncwa -h -O -a Nx $ice_analysis3 $ice_analysis3a_rg
fi

# Plotting
if [ -f flag_plot_sm_all ] || [ -f flag_plot_sm_atm ]; then
   
    ### Seasonal analysis ###
    
    # Zonal mean U
    python3 $script_plot_dir/plot_atm_meridional_mean_std.py --data-file=$atm_analysis11 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname-mean=U_SM --varname-std=U_SASTD --title="[$casename] Seasonal analysis of zonal wind" --colormap-mean=PuBuGn --colormap-std=hot_r --cmin-mean=0 --cmax-mean=75 --cmax-std=5 --clevs=15 --tick-levs-mean=15 --tick-levs-std=5 --scale="1"  --extra-filename="U" --idx-x=0 --clabel-mean="Mean [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]" --clabel-std="Standard deviation [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]" --lev-file="$diag_dir/atm_lev.nc" --subtitles="MAM,JJA,SON,DJF"

    # PSL
    python3 $script_plot_dir/plot_4seasons_contourf.py --data-file=$atm_analysis1 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname-mean=PSL_MM --varname-var=PSL_MAVAR --title="[$casename] Seasonal analysis of mixed-layer thickness" --colormap-mean=PuBuGn --colormap-std=hot_r --cmin-mean=950 --cmax-mean=1050 --cmax-std=10 --clevs=20 --tick-levs-mean=10 --tick-levs-std=10 --scale="100.0" --extra-filename="PSL" --idx-z=0 --clabel-mean="Mean [ \$ \\mathrm{hPa} \$ ]" --clabel-std="Standard deviation [ \$ \\mathrm{hPa} \$ ]"
    
    # Precipitation
    python3 $script_plot_dir/plot_4seasons_contourf.py --data-file=$atm_analysis4 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname-mean=PREC_TOTAL_MM --varname-var=PREC_TOTAL_MAVAR --title="[$casename] Seasonal analysis of precipitation" --colormap-mean=PuBuGn --colormap-std=hot_r --cmin-mean=0 --cmax-mean=3000 --cmax-std=3000 --clevs=10 --tick-levs-mean=10 --tick-levs-std=10 --scale="3.171e-11" --extra-filename="PREC_TOTAL" --idx-z=0 --clabel-mean="Mean [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]" --clabel-std="Standard deviation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]"

    # SST
    python3 $script_plot_dir/plot_4seasons_contourf.py --data-file=$ocn_analysis1_rg --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname-mean=T_ML_MM --varname-var=T_ML_MAVAR --title="[$casename] Seasonal analysis of sea surface temperature (SST)" --colormap-mean=gnuplot --colormap-std=hot_r --cmin-mean=0 --cmax-mean=30 --cmax-std=1 --clevs=15 --tick-levs-mean=15 --tick-levs-std=5 --scale="1.0" --extra-filename="SST" --idx-z=0 --clabel-mean="Mean [ \$ \\mathrm{K} \$ ]" --clabel-std="Standard deviation [ \$ \\mathrm{K} \$ ]"

    # MLD
    python3 $script_plot_dir/plot_4seasons_contourf.py --data-file=$ocn_analysis3_rg --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname-mean=HMXL_MM --varname-var=HMXL_MAVAR --title="[$casename] Seasonal analysis of mixed-layer thickness" --colormap-mean=PuBuGn --colormap-std=hot_r --cmin-mean=0.0 --cmax-mean=400 --cmax-std=500 --clevs=20 --tick-levs-mean=10 --tick-levs-std=10 --scale="1.0" --extra-filename="MLT" --idx-z=0 --clabel-mean="Mean [ \$ \\mathrm{m} \$ ]" --clabel-std="Standard deviation [ \$ \\mathrm{m} \$ ]"

    python3 $script_plot_dir/plot_SST.py --data-file=$atm_concat --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename
    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_dir --res=$res --casenames=$casename --data-file=$(basename $atm_analysis3) --varname=IAET_mean --ylabel="Energy flux [ \$ \\times 10^{15} \\, \\mathrm{W} \$ ]" --yscale="1e15" --domain-file=$atm_domain --colors="#000000"
    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_dir --res=$res --casenames=$casename --data-file=$(basename $atm_analysis4) --varname=total_precip_ZM --ylabel="Precipitation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain --colors="#000000"
    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_dir --res=$res --casenames=$casename --data-file=$(basename $atm_analysis4) --varname=total_precip_ZVAR --ylabel="Precipitation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain --colors="#000000"

    
    python3 $script_plot_dir/plot_contourf.py --data-file=$atm_analysis5 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname=PCAs --title="[$casename] PSLA 1st PCA (definition of AO)" --colormap=cmocean_balance --cmin=-1 --cmax=1 --clevs=20 --scale="1" --idx-t=0 --auto-clevs --extra-filename="_AO"
    # Referenced height temperature
    for i in $( seq 1 12 ); do
        echo ""
        python3 $script_plot_dir/plot_contourf.py --data-file=$atm_analysis2 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname=TREFHTMM --title="[$casename] Referenced height temperature (month $i)" --colormap=NCV_jet --cmin="-40" --cmax="40" --clevs=20 --idx-t=$(( $i - 1 )) --clabel="[ degC ]" --offset=273.15 --extra-filename="$( printf "_%02d" $i )" --land-transparent
        
    done
fi

if [ -f flag_plot_sm_all ] || [ -f flag_plot_sm_ocn ]; then

    # ocn
    for i in $( seq 1 12 ); do
        echo ""
        python3 $script_plot_dir/plot_ocean_diagnose.py --data-file-SSTAYYC=$ocn_concat_rg --data-file-SSTAVAR=$ocn_concat_rg --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --selected-month=$i
    done

    # ocn : PDO
#    python3 $script_plot_dir/plot_mc_climate_indices.py --input-dir=$diag_data_dir --output-dir=$graph_dir --res=$res --casenames=$casename --data-file=$(basename $ocn_concat_rg) --varname=PDO --normalize=no --colors="#000000"
    python3 $script_plot_dir/plot_contourf.py --data-file=$ocn_analysis2_rg --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname=PCAs --title="[$casename] SST 1st PCA (definition of PDO)" --colormap=cmocean_balance --cmin=-1 --cmax=1 --clevs=20 --scale="1" --idx-t=0 --auto-clevs  --extra-filename="_PDO"

fi

if [ -f flag_plot_sm_all ] || [ -f flag_plot_sm_ice ]; then
    # ice
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_dir --res=$res --casenames=$casename --data-file=$(basename $ice_analysis1) --varname=total_ice_volume --ylabel="Ice volume [ \$ \\mathrm{km^3} \$ ]" --yscale="1e9" --colors="#000000"
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_dir --res=$res --casenames=$casename --data-file=$(basename $ice_analysis1) --varname=total_ice_area --ylabel="Ice area fraction [ % ]" --yscale="1e-2" --colors="#000000"

    for i in $( seq 1 12 ); do
        echo ""
        python3 $script_plot_dir/plot_ice.py --data-file=$ice_analysis1 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --selected-month=$i
        python3 $script_plot_dir/plot_contourf.py --data-file=$ice_analysis1 --domain-file=$atm_domain --output-dir=$graph_dir --casename=$casename --varname=aice_MA --title="Sea-ice concentration month $i" --colormap=cmocean_tempo --cmin=10 --cmax=100 --clevs=10 --scale="1e-2" --idx-t=$(( $i - 1 )) --clabel="[ % ]" --extra-filename="$( printf "_%02d" $i )"
    done
fi
printf "Phase 2 takes %d seconds\n" $(( $SECONDS - $begin_t ))


