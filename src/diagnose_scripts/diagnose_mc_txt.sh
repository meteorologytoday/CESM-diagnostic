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
    diag-beg-year
    diag-end-year
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
script_analysis_dir=$script_root_dir/analysis


python3 $script_analysis_dir/mc_txt_analysis.py --input-dir=$diag_data_dir --output-dir=$graph_data_dir --casenames=$casenames --legends=$legends















