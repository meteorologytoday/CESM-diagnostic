#!/bin/bash

lopts=(
    A-dir
    B-dir
    AB-dir
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


if [ ! -d "$A_dir" ]; then
    echo "ERROR: Directory \"$A_dir\" does not exist."
    exit 1;
fi

if [ ! -d "$B_dir" ]; then
    echo "ERROR: Directory \"$B_dir\" does not exist."
    exit 1;
fi

mkdir -p "$AB_dir"

for f in $( ls "$A_dir" ); do
    
    f_A="$A_dir/$f"
    f_B="$B_dir/$f"
    f_AB="$AB_dir/$f"

    if [ ! -f "$f_B" ]; then
        echo "ERROR: File \"$f_B\" does not exist. Going to skip this file."
        continue
    fi
   
    ncdiff -O "$f_A" "$f_B" "$f_AB"

done
