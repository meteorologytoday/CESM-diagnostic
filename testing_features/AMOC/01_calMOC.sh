#!/bin/bash

output_dir=output_POP2_MOC
mkdir -p $output_dir

beg_year=1
end_year=600

for y in $( seq $beg_year $end_year ) ; do

    output_file=$( printf "$output_dir/MOC_%04d.nc" $y )

    if [[ -f "$output_file" ]] ; then
        echo "Skipping year $y"
    else 
        echo "Doing year $y"
        yr=$( printf "%04d" $y )
        cmd="ncra -v MOC ~/scratch-tienyiao/archive/qco2_POP2/ocn/hist/qco2_POP2.pop.h.${yr}-{01..12}.nc ${output_file}" 
        echo $cmd
        bash -c "ncra -v MOC ~/scratch-tienyiao/archive/qco2_POP2/ocn/hist/qco2_POP2.pop.h.${yr}-{01..12}.nc ${output_file}" 
    fi

done


yr_rng=$( printf "%04d..%04d" $beg_year $end_year )
bash -c "ncrcat -O -v MOC ${output_dir}/MOC_{${yr_rng}}.nc $output_dir/MOC_am.nc"
#ncra -O --mro -d time,,,12,12 $output_dir/MOC.nc  $output_dir/MOC_am.nc

echo "Done."
