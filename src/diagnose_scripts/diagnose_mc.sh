#!/bin/bash

lopts=(
    res
    label
    casenames
    legends
    sim-data-dir
    diag-data-dir
    graph-data-dir
    atm-domain
    ocn-domain
    colors
    linestyles
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


export wdir=`pwd`
export script_root_dir=$(dirname $0)
script_plot_dir=$script_root_dir/plot

mkdir -p $graph_data_dir

t_offset=$(( $t_offset - 1 ))

if [ -f flag_plot_mc ] || [ -f flag_plot_mc_timeseries ]; then
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis7.nc --varname=TREFHT_GLB --ylabel="Temperature [deg C]" --mavg=12 --extra-title="Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="273.15" --legends=$legends --yrng=[10.0,18.0]
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis7.nc --varname=TREFHT_LND --ylabel="Temperature [deg C]" --mavg=12 --extra-title="Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="273.15" --legends=$legends --yrng=[10.0,18.0]
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis7.nc --varname=TREFHT_OCN --ylabel="Temperature [deg C]" --mavg=12 --extra-title="Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="273.15" --legends=$legends --yrng=[10.0,18.0]

    
    # sea-ice area
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ice_analysis01_volume_area.nc --varname=ice_area_GLB --ylabel='Area [$ \times\, 10^6 \, \mathrm{km}^2$]' --mavg=12 --extra-title="Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="0"  --legends=$legends --yrng="" --yscale=1e12
    
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ice_analysis01_volume_area.nc --varname=ice_area_NH --ylabel='Area [$ \times\, 10^6 \, \mathrm{km}^2$]' --mavg=12 --extra-title="(NH) Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="0"  --legends=$legends --yrng="" --yscale=1e12
    
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ice_analysis01_volume_area.nc --varname=ice_area_SH --ylabel='Area [$ \times\, 10^6 \, \mathrm{km}^2$]' --mavg=12 --extra-title="(SH) Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="0"  --legends=$legends --yrng="" --yscale=1e12

    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ice_analysis01_volume_area.nc --varname=ice_volume_GLB --ylabel='Area [$ \times\, 10^3 \, \mathrm{km}^3$]' --mavg=12 --extra-title="Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="0"  --legends=$legends --yrng="" --yscale=1e12
    
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ice_analysis01_volume_area.nc --varname=ice_volume_NH --ylabel='Area [$ \times\, 10^3 \, \mathrm{km}^3$]' --mavg=12 --extra-title="(NH) Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="0"  --legends=$legends --yrng="" --yscale=1e12
    
    python3 $script_plot_dir/plot_mc_timeseries.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ice_analysis01_volume_area.nc --varname=ice_volume_SH --ylabel='Area [$ \times\, 10^3 \, \mathrm{km}^3$]' --mavg=12 --extra-title="(SH) Yearly average" --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --y-offset="0"  --legends=$legends --yrng="" --yscale=1e12


fi



if [ -f flag_plot_mc ] || [ -f flag_plot_mc_XY ]; then
    
    # ICEFRAC
    python3 $script_plot_dir/plot_mc_map_mean_std.py \
        --data-dir=$diag_data_dir                                     \
        --data-file=atm_analysis6_icefrac.nc                          \
        --casenames=$casenames                                        \
        --legends=$legends                                            \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_data_dir                                  \
        --varname-mean=ICEFRAC_SM                                     \
        --varname-std=ICEFRAC_SASTD                                   \
        --title="Seasonal analysis of sea-ice concentration"          \
        --colormap-mean=GnBu                                          \
        --colormap-std=hot_r                                          \
        --cmax-mean=100                                               \
        --cmin-mean=15                                                \
        --cmax-std=50                                                 \
        --clevs-mean=18                                               \
        --clevs-std=10                                                \
        --tick-levs-mean=18                                           \
        --tick-levs-std=10                                            \
        --scale="1e-2"                                                \
        --extra-filename="ICEFRAC"                                    \
        --idx-z=0                                                     \
        --clabel-mean="Mean [ \$ \\% \$ ]"                            \
        --clabel-std="Standard deviation [ \$ \\% \$ ]"               \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40

    # PSL
    python3 $script_plot_dir/plot_mc_map_mean_std.py \
        --data-dir=$diag_data_dir                                     \
        --data-file=atm_analysis1.nc                                  \
        --casenames=$casenames                                        \
        --legends=$legends                                            \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_data_dir                                  \
        --varname-mean=PSL_SM                                         \
        --varname-std=PSL_SASTD                                       \
        --title="Seasonal analysis of sea surface pressure relative to 1 atm"  \
        --colormap-mean=bwr                                           \
        --colormap-std=hot_r                                          \
        --cmax-mean=30                                                \
        --cmin-mean=-30                                               \
        --cmax-std=10                                                 \
        --clevs-mean=15                                               \
        --clevs-std=10                                                \
        --tick-levs-mean=15                                           \
        --tick-levs-std=10                                            \
        --offset="101300.0"                                           \
        --scale="100.0"                                               \
        --extra-filename="PSL"                                        \
        --idx-z=0                                                     \
        --clabel-mean="Mean [ \$ \\mathrm{hPa} \$ ]"                  \
        --clabel-std="Standard deviation [ \$ \\mathrm{hPa} \$ ]"     \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40

    # SST
    python3 $script_plot_dir/plot_mc_map_mean_std.py \
        --data-dir=$diag_data_dir                                     \
        --data-file=ocn_analysis1_SST_anomalies_rg.nc                 \
        --casenames=$casenames                                        \
        --legends=$legends                                            \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_data_dir                                  \
        --varname-mean=T_ML_SM                                         \
        --varname-std=T_ML_SASTD                                       \
        --title="Seasonal analysis of sea surface temperature"                     \
        --colormap-mean=gnuplot                                    \
        --colormap-std=hot_r                                     \
        --cmax-mean=30                                         \
        --cmin-mean=0                                            \
        --cmax-std=1                                           \
        --clevs-mean=15                                          \
        --clevs-std=10                                           \
        --tick-levs-mean=10                                      \
        --tick-levs-std=10                                        \
        --scale="1.0"                                             \
        --extra-filename="SST"                                     \
        --idx-z=0                                                     \
        --clabel-mean="Mean [ \$ { }^\\circ\\mathrm{C} \$ ]"               \
        --clabel-std="Standard deviation [ \$ { }^\\circ\\mathrm{C} \$ ]"  \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40

    # Precip
    python3 $script_plot_dir/plot_mc_map_mean_std.py \
        --data-dir=$diag_data_dir                                     \
        --data-file=atm_analysis4_precip.nc                           \
        --casenames=$casenames                                        \
        --legends=$legends                                            \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_data_dir                                  \
        --varname-mean=PREC_TOTAL_SM                                         \
        --varname-std=PREC_TOTAL_SASTD                                       \
        --title="Seasonal analysis of precipitation"                     \
        --colormap-mean=YlGnBu                                   \
        --colormap-std=hot_r                                     \
        --cmax-mean=3000                                         \
        --cmin-mean=0                                            \
        --cmax-std=1000                                           \
        --clevs-mean=10                                          \
        --clevs-std=10                                           \
        --tick-levs-mean=10                                      \
        --tick-levs-std=10                                        \
        --scale="1.0/1000/365/86400"                                  \
        --extra-filename="PREC_TOTAL"                                \
        --idx-z=0                                                     \
        --clabel-mean="Mean [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]"               \
        --clabel-std="Standard deviation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]"  \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40


fi

if [ -f flag_plot_mc ] || [ -f flag_plot_mc_YZ ]; then

    # U
    python3 $script_plot_dir/plot_mc_atm_meridional_mean_std.py \
        --data-dir=$diag_data_dir                                     \
        --data-file=atm_analysis11_U.nc                               \
        --casenames=$casenames                                        \
        --legends=$legends                                            \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_data_dir                                  \
        --varname-mean=U_SM                                           \
        --varname-std=U_SASTD                                         \
        --title="Seasonal analysis of zonal wind"                     \
        --colormap-mean=bwr                                      \
        --colormap-std=hot_r                                       \
        --cmax-mean=50                                           \
        --cmin-mean=-50                                          \
        --cmax-std=5                                             \
        --clevs-mean=20                                          \
        --clevs-std=10                                           \
        --tick-levs-mean=20                                      \
        --tick-levs-std=10                                       \
        --scale="1"                                                   \
        --extra-filename="U"                                          \
        --idx-x=0                                                     \
        --clabel-mean="Mean [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"               \
        --clabel-std="Standard deviation [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"  \
        --lev-file="atm_lev.nc"        \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40


    # Streamfunction
    python3 $script_plot_dir/plot_mc_atm_meridional_mean_std.py \
        --data-dir=$diag_data_dir                                     \
        --data-file=atm_analysis12_psi.nc                             \
        --casenames=$casenames                                        \
        --legends=$legends                                            \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_data_dir                                  \
        --varname-mean=psi_SM                                         \
        --varname-std=psi_SASTD                                       \
        --title="Seasonal analysis of Streamfunction"                 \
        --colormap-mean=bwr                                      \
        --colormap-std=hot_r                                       \
        --cmax-mean=15                                           \
        --cmin-mean=-15                                          \
        --cmax-std=2                                             \
        --clevs-mean=10                                          \
        --clevs-std=8                                            \
        --tick-levs-mean=10                                      \
        --tick-levs-std=8                                        \
        --scale="1e8"                                                 \
        --extra-filename="psi"                                        \
        --idx-x=0                                                     \
        --clabel-mean="Mean [ \$ \\mathrm{kg} \, \\mathrm{s}^{-1} \$ ]"               \
        --clabel-std="Standard deviation [ \$ \\mathrm{kg} \, \\mathrm{s}^{-1} \$ ]"  \
        --lev-file="atm_ilev.nc"        \
        --lev-varname=ilev        \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40

fi

if [ -f flag_plot_mc ] || [ -f flag_plot_mc_climate_indices ]; then


    python3 $script_plot_dir/plot_mc_climate_indices.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis2_rg_PDO.nc --varname=PDO --colors="$colors" --linestyles="$linestyles" --t-offset=$t_offset --legends=$legends --mavg=6
    python3 $script_plot_dir/plot_mc_climate_indices.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis5_AO.nc --varname=AO --colors="$colors" --linestyles="$linestyles"  --t-offset=$t_offset --legends=$legends --mavg=6
    python3 $script_plot_dir/plot_mc_climate_indices.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis11_rg_EN34.nc --varname=EN34 --colors="$colors" --linestyles="$linestyles"  --t-offset=$t_offset --legends=$legends --mavg=6
    python3 $script_plot_dir/plot_mc_climate_indices.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis11_rg_EN34.nc --varname=ENSO --colors="$colors" --linestyles="$linestyles"  --t-offset=$t_offset --legends=$legends --mavg=6

fi

if [ -f flag_plot_mc ] || [ -f flag_plot_mc_Y ]; then
    
    # Implied Oceanic Energy Transport (IOET) 
    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis13_rg_IOET.nc --varname=IOET_AM --ylabel="Energy flux [ \$ \\times 10^{15} \\, \\mathrm{W} \$ ]" --yscale="1e15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles" --legends=$legends
#    python3 $script_plot_dir/plot_mc_ocn_energy.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis12_rg_energy.nc --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles" --legends=$legends

    #python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis3_energy.nc --varname=IAET_mean --ylabel="Energy flux [ \$ \\times 10^{15} \\, \\mathrm{W} \$ ]" --yscale="1e15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles" --legends=$legends
   
    # Implied Atmospheric Energy Transport (IAET) 
    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis3_energy.nc --varname=IAET_AM --ylabel="Energy flux [ \$ \\times 10^{15} \\, \\mathrm{W} \$ ]" --yscale="1e15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles" --legends=$legends
    

#    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis9b_rg_oiet_avg.nc --varname=IET_OCN_ZONAL_MEAN --ylabel="Energy flux [ \$ \\times 10^{15} \\, \\mathrm{W} \$ ]" --yscale="1e15" --domain-file=$atm_domain --colors="$colors" --indexing="0,:" --linestyles="$linestyles" --legends=$legends

#    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis3_energy.nc --varname=L_IET --ylabel="Energy flux [ \$ \\times 10^{15} \\, \\mathrm{W} \$ ]" --yscale="1e15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles" --legends=$legends

    #python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis4_precip.nc --varname=total_precip_ZM --ylabel="Precipitation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends
    #python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis4_precip.nc --varname=total_precip_ZVAR --ylabel="Precipitation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends
    
    #python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis4_precip.nc --varname-mean=PREC_TOTAL_ZONAL_MEAN --varname-var=PREC_TOTAL_ZONAL_MAVAR --ylabel="Precipitation [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain -colors="$colors" --linestyles="$linestyles"  --legends=$legends

#    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis2.nc --varname=TREFHT_ZM --ylabel="Temperature [ \$ \\mathrm{K} \$ ]" --yscale="1" --y-offset="273.15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends
#    python3 $script_plot_dir/plot_mc_meridional.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis2.nc --varname=TREFHT_ZVAR --ylabel="Temperature [ \$ \\mathrm{K} \$ ]" --yscale="1" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends

    # TREFHT
    python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis2a.nc --varname-mean=TREFHT_AM --varname-var=TREFHT_AAVAR --ylabel="Temperature [ \$ \\mathrm{K} \$ ]" --yscale="1" --y-offset="273.15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="TREFHT" --y-range-mean="-30,30" --y-range-std="0,8"


    # MLD
   python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis3a_rg_MLD.nc --varname-mean=h_ML_AM --varname-var=h_ML_AAVAR --ylabel="Mixed-layer Depth [ \$ \\mathrm{m} \$ ]" --yscale="1" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="Mixed-Layer Depth" --y-range-mean="0,500" --y-range-std="0,300" --invert-y-axis

    # PRECIP    
    python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis4a_precip.nc --varname-mean=PREC_TOTAL_AM --varname-var=PREC_TOTAL_AAVAR --ylabel="Precipitation [ \$ \\mathrm{mm} / year \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="Precipitation" --y-range-mean="0,4000" --y-range-std="0,1500"

    # ICEFRAC
    python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis6a_icefrac.nc --varname-mean=ICEFRAC_AM --varname-var=ICEFRAC_AAVAR --ylabel="Concentration [ \$ \\% \$ ]" --yscale="1e-2" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="Sea-ice Fraction" --y-range-mean="0,100" --y-range-std="0,50"

    # Solar surface flux
    #python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis7a_rg_swflx.nc --varname-mean=swflx_AM --varname-var=swflx_AAVAR --ylabel="Energy density flux [ \$ \\mathrm{W} \\, \\mathrm{m}^{-2} \$ ]" --yscale="-1.0" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="Solar surface flux" --y-range-mean="0,300" --y-range-std="0,50"

    # Non-solar surface flux
    #python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis8a_rg_nswflx.nc --varname-mean=nswflx_AM --varname-var=nswflx_AAVAR --ylabel="Energy density flux [ \$ \\mathrm{W} \\, \\mathrm{m}^{-2} \$ ]" --yscale="-1.0" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="Non-solar surface flux" --y-range-mean="-200, 100" --y-range-std="0,50"

    # Ekman dTdt
    #python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis5a_rg_T_hadvs.nc --varname-mean=T_hadvs_AM --varname-var=T_hadvs_AAVAR --ylabel="Temperature tendency [ \$ \\mathrm{K} \\, \\mathrm{mon}^{-1} \$ ]" --yscale="3.858e-7" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="0,0,:" --extra-title=" Annual mean" --extra-filename="annual_mean" --display-varname="Temperature change caused by horizontal advection" --y-range-mean="-1, 1" --y-range-std="0,1"


    for m in $( seq 1 12 ); do
        indexing=$( printf "%d,0,:" $(( m - 1 )) )

    
        # TREFHT
        python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis2a.nc --varname-mean=TREFHT_MM --varname-var=TREFHT_MAVAR --ylabel="Temperature [ \$ \\mathrm{deg C} \$ ]" --yscale="1" --y-offset="273.15" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="$(( $m - 1 )),0,:" --extra-title=" Month $m" --extra-filename="$(printf '%02d' $m)" --display-varname="Referenced Height Temperature" --y-range-mean="-30,30" --y-range-std="0,8"


        # h_ML
        python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis3a_rg_MLD.nc --varname-mean=h_ML_MM --varname-var=h_ML_MAVAR --ylabel="Mixed-layer Depth [ \$ \\mathrm{m} \$ ]" --yscale="1" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="$(( $m - 1 )),0,:" --extra-title=" Month $m" --extra-filename="$(printf '%02d' $m)" --display-varname="Mixed-Layer Depth" --y-range-mean="0,500" --y-range-std="0,300" --invert-y-axis


        # PRECIP
        python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis4a_precip.nc --varname-mean=PREC_TOTAL_MM --varname-var=PREC_TOTAL_MAVAR --ylabel="Precipitation [ \$ \\mathrm{mm} / year \$ ]" --yscale="3.171e-11" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="$(( $m - 1 )),0,:" --extra-title=" Month $m" --extra-filename="$(printf '%02d' $m)" --display-varname="Precipitation" --y-range-mean="0,5000" --y-range-std="0,2000"
        
        # ICEFRAC
        python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=atm_analysis6a_icefrac.nc --varname-mean=ICEFRAC_MM --varname-var=ICEFRAC_MAVAR --ylabel="Concentration [ \$ \\% \$ ]" --yscale="1e-2" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="$(( $m - 1)),0,:" --extra-title=" Month $m" --extra-filename="$(printf '%02d' $m)" --display-varname="Sea-ice Fraction" --y-range-mean="0,100" --y-range-std="0,50"

        # dTdt horizontal advection
        #python3 $script_plot_dir/plot_mc_meridional_mean_std.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --data-file=ocn_analysis5_rg_T_hadvs.nc --varname-mean=T_hadvs_MM --varname-var=T_hadvs_MAVAR --ylabel="Temperature Tendency [ \$ \\mathrm{K} \\, \\mathrm{mon}^{-1} \$ ]" --yscale="3.858e-7" --domain-file=$atm_domain --colors="$colors" --linestyles="$linestyles"  --legends=$legends --indexing="$(( $m - 1)),0,:" --extra-title=" Month $m" --extra-filename="$(printf '%02d' $m)" --display-varname="Temperature Tendency caused by horizontal advection" --y-range-mean="-1, 1" --y-range-std="0,1"
 

    done

fi
