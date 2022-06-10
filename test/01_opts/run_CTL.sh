#!/bin/bash

tasks=0
max_tasks=1
for model in EMOM ; do
    
    tasks=$(( tasks + 1 ))

    casename="qco2_${model}"
  
    echo "$tasks"

    julia ../../src/diagnose_scripts_julia/diagnose_model_opt.jl --diag-file diagnose_setting_CTL.toml --diagcase $casename --diag-opt diag_opts.toml  &
    
    if (( tasks == max_tasks )); then
        echo "Notice: max_tasks reached. Wait now."
        tasks=0
        wait
    fi

done
