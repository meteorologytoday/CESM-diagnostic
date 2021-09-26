#!/bin/bash

echo "Transforming data..."

old_files=""
new_files=""

if [ ! -f flag_notrans_ice ] ; then

    for y in $( seq $diag_beg_year $diag_end_year ); do
        for m in $( seq 1 12 ); do

            # vice
            old_file=$casename.cice.h.$( printf "%04d-%02d" $y $m ).nc
            new_file=$( echo "$old_file" | sed -e 's/\.cice\./.cice_extra./' )

            if [ ! -f "$concat_dir/$new_file" ]; then 
                ((ii=ii%4)); ((ii++==0)) && wait
                echo "[sum to get vice] $new_file does not exist, need to transform."
                ncap2 -h -O -v \
                    -s 'vice=vicen001+vicen002+vicen003+vicen004+vicen005;' \
                    -s 'aice=(aicen001+aicen002+aicen003+aicen004+aicen005)/100.0;' \
                    $ice_hist_dir/$old_file $concat_dir/$new_file
            fi
        done
    done

    echo "Done summing ice types."

    for y in $( seq $diag_beg_year $diag_end_year ); do
        for m in $( seq 1 12 ); do

            old_file=$casename.cice_extra.h.$( printf "%04d-%02d" $y $m ).nc
            new_file_bilinear=$( echo "$old_file" | sed -e 's/\.cice_extra\./.cice_extra2_rg./' )
            
            if [ ! -f "$concat_dir/$new_file_bilinear" ]; then 
                echo "[Transoform ice to rg] $new_file_bilinear does not exist, need to transform."
                old_files="${old_file},${old_files}"
                new_files_bilinear="${new_file_bilinear},${new_files_bilinear}"
            fi
        done
    done



    if [ "$old_files" != "" ] ; then

        julia $script_coordtrans_dir/transform_data.jl --s-file=$old_files --d-file=$new_files_bilinear --w-file=${wgt_dir}/wgt.bilinear.nc --algo=ESMF --vars=aice,vice --x-dim=ni --y-dim=nj --t-dim=time --s-dir=$concat_dir --d-dir=$concat_dir
        
    else
        echo "All files are transformed. Nothing to do here."
    fi

    echo "Done transform ice coord."
fi
