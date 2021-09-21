#!/bin/bash
export script_dir=$( dirname "$(realpath $0)" )
export script_plot_dir=$script_dir/plot

# ===== [BEGIN] READ PARAMETERS =====

lopts=(
    case-settings
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


# ===== [END] READ PARAMETERS =====

source "$case_settings"

function join_by { local IFS="$1"; shift; echo "$*"; }


if [ ]; then
casenames=()
legends=()
colors=()
linestyles=()


ref_casenames=()
ref_legends=()


for i in $(seq 1 $((${#compare_cases[@]}/4))); do
    
    casename=${compare_cases[$((4*(i-1)))]}
    legend=${compare_cases[$((4*(i-1)+1))]}
    color=${compare_cases[$((4*(i-1)+2))]}
    linestyle=${compare_cases[$((4*(i-1)+3))]}

    casenames+=($casename)
    legends+=($legend)
    colors+=($color)
    linestyles+=($linestyle)

    ref_casename=${ref_cases[$((4*(i-1)))]}
    ref_legend=${ref_cases[$((4*(i-1)+1))]}
    
    ref_casenames+=($ref_casename)
    ref_legends+=($ref_legend)
    
done

if [ ! -f flag_no_cal_diffcase ] ; then

    for i in $(seq 1 $((${#casenames[@]}))); do
        
        casename=${casenames[$((i-1))]}
        
        printf "Comparing case: [%s] - [%s]\n" $casename $ref_casename
        $script_dir/diff_case.sh --A-dir="${A_dir}/$casename" --B-dir="${B_dir}/${ref_casename}" --AB-dir="${AB_dir}/${casename}_minus_${ref_casename}"
         
    done
fi
fi





mkdir -p $graph_dir

if [ -f flag_plot_diffcase ] || [ -f flag_plot_diffcase_Y ]; then


    set -x
    # Diff MLT
    python3 $script_plot_dir/plot_diffcase_meridional_mean_std.py     \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=ocn_analysis3_rg_MLD.nc                           \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --indexing="0,0,:"                                            \
        --varname-mean=h_ML_ZONAL_AM                                  \
        --varname-std=h_ML_ZONAL_AASTD                                \
        --title="Annual Mean of MLT"                                  \
        --invert-yaxis                                                \
        --yscale=1.0                                                  \
        --ylabel-mean=" \$ \\Delta \$MLT mean [ \$ \\mathrm{m} \$ ]"  \
        --ylabel-std=" \$ \\Delta \$MLT std [ \$ \\mathrm{m} \$ ]"    \
        --extra-filename="h_ML"                                       \
        --colors=$( join_by , "${colors[@]}" )                        \
        --linestyles=$( join_by , "${linestyles[@]}" )                \
        --ymax-mean=100                                               \
        --ymax-std=50                                                 \
        --tick-levs-mean=25                                           \
        --tick-levs-std=10                                            \
        --figsize=15,10
    
    for m in $(seq 1 12); do
        # Diff MLT
        python3 $script_plot_dir/plot_diffcase_meridional_mean_std.py     \
            --data-dir=$A_dir                                             \
            --ref-data-dir=$B_dir                                         \
            --data-file=ocn_analysis3_rg_MLD.nc                           \
            --casenames=$( join_by , "${casenames[@]}")                   \
            --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
            --legends=$( join_by , "${legends[@]}")                       \
            --domain-file=$atm_domain                                     \
            --output-dir=$graph_dir                                       \
            --indexing="$(( $m - 1 )),0,:"                                \
            --varname-mean=h_ML_ZONAL_MM                                  \
            --varname-std=h_ML_ZONAL_MASTD                                \
            --title="$( printf "MLT of month %d" $m)"                     \
            --invert-yaxis                                                \
            --yscale=1.0                                                  \
            --ylabel-mean=" \$ \\Delta \$MLT mean [ \$ \\mathrm{m} \$ ]"  \
            --ylabel-std=" \$ \\Delta \$MLT std [ \$ \\mathrm{m} \$ ]"    \
            --extra-filename=$( printf "h_ML_%02d" $m )                   \
            --colors=$( join_by , "${colors[@]}" )                        \
            --linestyles=$( join_by , "${linestyles[@]}" )                \
            --ymax-mean=200                                               \
            --ymax-std=50                                                 \
            --tick-levs-mean=25                                           \
            --tick-levs-std=10                                            \
            --figsize=15,10
    done

    # Diff IAET
    python3 $script_plot_dir/plot_diffcase_meridional_mean_std.py     \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis3_energy.nc                           \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=IAET_AM                                        \
        --varname-std=IAET_AMSTD                                      \
        --title="[ $scenario minus $ref_scenario ] IAET change      " \
        --colormap-mean-diff=bwr                                      \
        --colormap-std-diff=bwr                                       \
        --ymax-mean-diff=5                                            \
        --ymax-std-diff=0.5                                           \
        --tick-levs-mean-diff=10                                      \
        --tick-levs-std-diff=10                                       \
        --scale-mean="1e15"                                           \
        --scale-std="1e13"                                            \
        --extra-filename="IAET"                                       \
        --idx-z=0                                                     \
        --clabel-mean-diff=" Mean difference [ \$ \\mathrm{PW} \$ ]"        \
        --clabel-std-diff=" Standard deviation difference [ \$ \\times 10^{2} \, \\mathrm{PW} \$ ]"        \
        --figsize=8,6


fi


if [ -f flag_plot_diffcase ] || [ -f flag_plot_diffcase_XY ]; then

    # Diff PRECIP
    python3 $script_plot_dir/plot_diffcase_map_contourf.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis4_precip.nc                           \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=PREC_TOTAL_AM                                           \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of zonal wind" \
        --colormap-mean-diff=BrBG                                     \
        --cmax-mean-diff=500                                          \
        --clevs-mean-diff=10                                          \
        --tick-levs-mean-diff=10                                      \
        --scale="1/86400/365/1000"                                    \
        --extra-filename="PREC_TOTAL"                          \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]"               \
        --figsize=20,20

    # Diff SST
    python3 $script_plot_dir/plot_diffcase_map_contourf.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=ocn_analysis1_SST_anomalies_rg.nc                 \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=T_ML_AM                                           \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of sea surface temperature" \
        --colormap-mean-diff=bwr                                      \
        --cmax-mean-diff=2.0                                          \
        --clevs-mean-diff=10                                          \
        --tick-levs-mean-diff=10                                      \
        --scale="1"                                                   \
        --extra-filename="SST"                                        \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ { }^\\circ\\mathrm{C} \$ ]"        \
        --figsize=20,20



    # Diff ICEFRAC
    python3 $script_plot_dir/plot_diffcase_map_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis6_icefrac.nc                          \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=ICEFRAC_SM                                     \
        --varname-std=ICEFRAC_SASTD                                   \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of sea-ice concentration" \
        --colormap-mean-diff=BrBG                                     \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=50                                           \
        --cmax-std-diff=25                                            \
        --clevs-mean-diff=20                                          \
        --clevs-std-diff=10                                           \
        --tick-levs-mean-diff=20                                      \
        --tick-levs-std-diff=10                                       \
        --scale="1e-2"                                                \
        --extra-filename="ICEFRAC"                                    \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ \\% \$ ]"                  \
        --clabel-std-diff="Standard deviation diff [ \$ \\% \$ ]"     \
        --lev-file="$A_dir/${casenames[0]}/atm_lev.nc"                \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,20



    # Diff SST
    python3 $script_plot_dir/plot_diffcase_map_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=ocn_analysis1_SST_anomalies_rg.nc                 \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=T_ML_SM                                           \
        --varname-std=T_ML_SASTD                                         \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of sea surface temperature" \
        --colormap-mean-diff=bwr                                      \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=2.0                                          \
        --cmax-std-diff=0.5                                           \
        --clevs-mean-diff=10                                          \
        --clevs-std-diff=10                                           \
        --tick-levs-mean-diff=10                                      \
        --tick-levs-std-diff=10                                        \
        --scale="1"                                                   \
        --extra-filename="SST"                                        \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ { }^\\circ\\mathrm{C} \$ ]"        \
        --clabel-std-diff="Standard deviation diff [ \$ { }^\\circ\\mathrm{C} \$ ]"  \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,20

    # Diff PSL
    python3 $script_plot_dir/plot_diffcase_map_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis1.nc                               \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=PSL_SM                                           \
        --varname-std=PSL_SASTD                                         \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of sea surface pressure" \
        --colormap-mean-diff=bwr                                      \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=5                                           \
        --cmax-std-diff=1                                             \
        --clevs-mean-diff=10                                          \
        --clevs-std-diff=4                                            \
        --tick-levs-mean-diff=10                                      \
        --tick-levs-std-diff=4                                        \
        --scale="100"                                                   \
        --extra-filename="PSL"                                          \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ \\mathrm{hPa} \$ ]"        \
        --clabel-std-diff="Standard deviation diff [ \$ \\mathrm{hPa} \$ ]"  \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,20


    # Diff PRECIP
    python3 $script_plot_dir/plot_diffcase_map_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis4_precip.nc                           \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=PREC_TOTAL_SM                                           \
        --varname-std=PREC_TOTAL_SASTD                                         \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of zonal wind" \
        --colormap-mean-diff=BrBG                                     \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=500                                          \
        --cmax-std-diff=200                                           \
        --clevs-mean-diff=10                                          \
        --clevs-std-diff=10                                           \
        --tick-levs-mean-diff=10                                      \
        --tick-levs-std-diff=10                                       \
        --scale="1/86400/365/1000"                                    \
        --extra-filename="PREC_TOTAL"                                 \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]"               \
        --clabel-std-diff="Standard deviation diff [ \$ \\mathrm{mm} \, \\mathrm{yr}^{-1} \$ ]"  \
        --lev-file="$A_dir/${casenames[0]}/atm_lev.nc"                \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,20

    # Diff h_ML
    python3 $script_plot_dir/plot_diffcase_map_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=ocn_analysis3_rg_MLD.nc                           \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=h_ML_SM                                           \
        --varname-std=h_ML_SASTD                                         \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of mixed-layer thickness" \
        --colormap-mean-diff=bwr                                      \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=20                                           \
        --cmax-std-diff=5                                             \
        --clevs-mean-diff=10                                          \
        --clevs-std-diff=10                                           \
        --tick-levs-mean-diff=10                                      \
        --tick-levs-std-diff=10                                       \
        --scale="1"                                                   \
        --extra-filename="MLT"                                        \
        --idx-z=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ \\mathrm{m} \$ ]"        \
        --clabel-std-diff="Standard deviation diff [ \$ \\mathrm{m} \$ ]"  \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40

    # Diff streamfunction
    python3 $script_plot_dir/plot_diffcase_atm_meridional_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis12_psi.nc                               \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=psi_SM                                           \
        --varname-std=psi_SASTD                                         \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of zonal wind" \
        --colormap-mean-diff=bwr                                      \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=5                                            \
        --cmax-std-diff=0.5                                           \
        --clevs-mean-diff=20                                          \
        --clevs-std-diff=10                                           \
        --tick-levs-mean-diff=20                                      \
        --tick-levs-std-diff=10                                       \
        --scale="1e8"                                                 \
        --extra-filename="psi"                                          \
        --idx-x=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ 1 \\times 10^8 \, \\mathrm{kg} \, \\mathrm{s}^{-1} \$ ]"               \
        --clabel-std-diff="Standard deviation diff [ \$ 1 \\times 10^8 \, \\mathrm{kg} \, \\mathrm{s}^{-1} \$ ]"  \
        --lev-file="$A_dir/${casenames[0]}/atm_ilev.nc"                \
        --lev-varname="ilev"                \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40


    # Diff U
    python3 $script_plot_dir/plot_diffcase_atm_meridional_mean_std.py \
        --data-dir=$A_dir                                             \
        --ref-data-dir=$B_dir                                         \
        --data-file=atm_analysis11_U.nc                               \
        --casenames=$( join_by , "${casenames[@]}")                   \
        --ref-casenames=$( join_by , "${ref_casenames[@]}")           \
        --legends=$( join_by , "${legends[@]}")                       \
        --domain-file=$atm_domain                                     \
        --output-dir=$graph_dir                                       \
        --varname-mean=U_SM                                           \
        --varname-std=U_SASTD                                         \
        --title="[ $scenario minus $ref_scenario ] Seasonal analysis of zonal wind" \
        --colormap-mean-diff=bwr                                      \
        --colormap-std-diff=bwr                                       \
        --cmax-mean-diff=5                                           \
        --cmax-std-diff=0.5                                             \
        --clevs-mean-diff=10                                          \
        --clevs-std-diff=10                                            \
        --tick-levs-mean-diff=10                                      \
        --tick-levs-std-diff=10                                        \
        --scale="1"                                                   \
        --extra-filename="U"                                          \
        --idx-x=0                                                     \
        --clabel-mean-diff="Mean diff [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"               \
        --clabel-std-diff="Standard deviation diff [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"  \
        --lev-file="$A_dir/${casenames[0]}/atm_lev.nc"                \
        --subtitles="MAM,JJA,SON,DJF"                                 \
        --figsize=20,40
    exit
    if [ ] ; then
    for i in $(seq 1 $((${#casenames[@]}))); do
        
        casename=${casenames[$((i-1))]}
        A_casename_dir="${A_dir}/$casename"
        B_casename_dir="${B_dir}/${ref_casename}"
        AB_casename_dir="${AB_dir}/${casename}_minus_${ref_casename}"
        legend=${legends[$((i-1))]}
  
        ref_casename=${ref_casenames[$((i-1))]}
        ref_legend=${ref_legends[$((i-1))]}
 
        # Diff U 
        python3 $script_plot_dir/plot_atm_meridional_mean_std_diffcase.py \
            --data-file-1=$A_casename_dir/atm_analysis11_U.nc             \
            --data-file-2=$B_casename_dir/atm_analysis11_U.nc             \
            --domain-file=$atm_domain                                     \
            --output-dir=$graph_dir                                       \
            --varname-mean=U_SM                                           \
            --varname-std=U_SASTD                                         \
            --title="[$legend V.S. $ref_legend] Seasonal analysis of zonal wind" \
            --colormap-mean=bwr                                           \
            --colormap-std=hot_r                                          \
            --colormap-mean-diff=bwr                                      \
            --colormap-std-diff=bwr                                       \
            --cmin-mean=-50                                               \
            --cmax-mean=50                                                \
            --cmax-std=5                                                  \
            --cmax-mean-diff=10                                           \
            --cmax-std-diff=2                                             \
            --clevs-mean=10                                               \
            --clevs-std=5                                                 \
            --clevs-mean-diff=10                                          \
            --clevs-std-diff=4                                            \
            --tick-levs-mean=10                                           \
            --tick-levs-std=5                                             \
            --tick-levs-mean-diff=10                                      \
            --tick-levs-std-diff=4                                        \
            --scale="1"                                                   \
            --extra-filename="U"                                          \
            --idx-x=0                                                     \
            --clabel-mean="Mean [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"\
            --clabel-std="Standard deviation [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"            \
            --clabel-mean-diff="Mean diff [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"               \
            --clabel-std-diff="Standard deviation diff [ \$ \\mathrm{m} \, \\mathrm{s}^{-1} \$ ]"  \
            --lev-file="$A_casename_dir/atm_lev.nc"                                                \
            --subtitles="MAM,JJA,SON,DJF"
    
    
    done
    fi
fi


exit;
