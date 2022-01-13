#!/bin/bash

export script_dir=$( dirname "$(realpath $0)" )
export script_coordtrans_dir="$script_dir/../CoordTrans"

echo "script_dir=$script_dir" 
echo "script_coordtrans_dir=$script_coordtrans_dir" 


# ===== [BEGIN] READ PARAMETERS =====

lopts=(
    case-settings
    stop-after-phase1
    plot-mc-only
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

# Output kill process shell.
echo "$(cat <<EOF
#!/bin/bash
kill -9 -$$
EOF
)" > kill_process.sh
chmod +x kill_process.sh

function join_by { local IFS="$1"; shift; echo "$*"; }


casenames=()
legends=()
colors=()
linestyles=()
offset_years=()

for i in $(seq 1 $((${#case_settings[@]}/5))); do
    casename=${case_settings[$((5*(i-1)))]}
    legend=${case_settings[$((5*(i-1)+1))]}
    color=${case_settings[$((5*(i-1)+2))]}
    linestyle=${case_settings[$((5*(i-1)+3))]}
    offset_year=${case_settings[$((5*(i-1)+4))]}
    printf "[%s] => [%s, %s]\n" $casename $color $linestyle

    casenames+=($casename)
    legends+=($legend)
    colors+=($color)
    linestyles+=($linestyle)
    offset_years+=( $offset_year )
done


if [ ! -d "$sim_data_dir" ] ; then
    echo "Error: sim_data_dir='$sim_data_dir' does not exist. "
    exit 1
fi

result_dir=$( printf "%s/result" `pwd`)
concat_data_dir=$( printf "%s/concat" $result_dir )
diag_data_dir=$( printf "%s/%04d-%04d/diag" $result_dir $diag_beg_year $diag_end_year )
graph_data_dir=$( printf "%s/%04d-%04d/graph" $result_dir $diag_beg_year $diag_end_year )

if [ ! -f "$atm_domain" ] ; then
    echo "Error: atm_domain="$atm_domain" does not exists."
    exit 1
fi

if [ ! -f "$ocn_domain" ] ; then
    echo "Error: atm_domain="$ocn_domain" does not exists."
    exit 1
fi


# Parallel loop : https://unix.stackexchange.com/questions/103920/parallelize-a-bash-for-loop

if (( ptasks == 0 )); then
    ptasks=1
fi

echo "### Parallization (ptasks) in batch of $ptasks ###"

# Transform ocn grid to atm grid

source $script_dir/lib_filename.sh

wgt_dir="wgt_$( filename $ocn_domain )_to_$( filename $atm_domain )"

$script_coordtrans_dir/generate_weight.sh    \
    --s-file=$ocn_domain                     \
    --d-file=$atm_domain                     \
    --output-dir="$wgt_dir"                  \
    --s-mask-value=1.0                       \
    --d-mask-value=0.0

if [ "$plot_mc_only" == "" ]; then

    for (( k=0; k < ${#casenames[@]} ; k++ )); do
#    for casename in "${casenames[@]}"; do

        (( i = (i + 1) % ptasks )); (( i == 0 )) && wait

        casename=${casenames[$k]}
        legend=${legends[$k]}
        offset_year=${offset_years[$k]}

        echo "Case: $casename"

        real_diag_beg_year=$(( offset_year + diag_beg_year ))
        real_diag_end_year=$(( offset_year + diag_end_year ))

        echo "Diag year: "


        full_casename=${label}_${res}_${casename}
        $script_dir/diagnose_single_model.sh \
            --casename=$casename                \
            --output-name=$legend               \
            --sim-data-dir=$sim_data_dir        \
            --concat-data-dir=$concat_data_dir  \
            --diag-data-dir=$diag_data_dir      \
            --graph-data-dir=$graph_data_dir    \
            --diag-beg-year=$real_diag_beg_year \
            --diag-end-year=$real_diag_end_year \
            --atm-domain=$atm_domain            \
            --ocn-domain=$ocn_domain            \
            --wgt-dir=$wgt_dir                  \
            --stop-after-phase1=$stop_after_phase1 \
            --PCA-sparsity=$PCA_sparsity        & 
    done

    wait

fi

echo "Start doing model comparison..."

echo "Running diagnose_mc.sh"
$script_dir/diagnose_mc.sh     \
    --casenames=$( join_by , "${legends[@]}") \
    --legends=$( join_by , "${legends[@]}") \
    --sim-data-dir=$sim_data_dir                \
    --diag-data-dir=$diag_data_dir              \
    --graph-data-dir=$graph_data_dir            \
    --atm-domain=$atm_domain                    \
    --ocn-domain=$ocn_domain                    \
    --colors=$( join_by , "${colors[@]}")       \
    --linestyles=$( join_by , "${linestyles[@]}"),     # The comma at the end is necessary. Argparse does not parse "--" as a string however it thinks "--," is a string. 

wait

echo "Done."

