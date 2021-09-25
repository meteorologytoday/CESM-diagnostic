#!/bin/bash

echo "Transforming data..."

old_files=""
new_files=""

if [ ! -f flag_notrans_atm ] ; then

    
    for y in $( seq $diag_beg_year $diag_end_year ); do
        for m in $( seq 1 12 ); do

            # PREC_TOTAL
            old_file=$casename.cam.h0.$( printf "%04d-%02d" $y $m ).nc
            new_file=$( echo "$old_file" | sed -e 's/\.cam\./.cam_extra./' )

            if [ ! -f "$concat_dir/$new_file" ]; then 
                ((ii=ii%4)); ((ii++==0)) && wait
                echo "$new_file does not exist, need to transform."
                ncap2 -h -O -v -s 'PREC_TOTAL=PRECC+PRECL;' $atm_hist_dir/$old_file $concat_dir/$new_file
            fi


            # Zonal mean field such as T, U, V
            old_file=$casename.cam.h0.$( printf "%04d-%02d" $y $m ).nc
            new_file=$( echo "$old_file" | sed -e 's/\.cam\./.cam_extra2_zonal_mean./' )
            if [ ! -f "$concat_dir/$new_file" ]; then 
                ((i=i%4)); ((i++==0)) && wait
                echo "$new_file does not exist, need to transform."
                #ncwa -O -a lon -v T,U,V,VU,VT,VQ,ilev $atm_hist_dir/$old_file $concat_dir/$new_file
                ncwa -O -a lon -v T,U,V,ilev $atm_hist_dir/$old_file $concat_dir/$new_file
                #ncwa -O -a lon -v U,V,ilev $atm_hist_dir/$old_file $concat_dir/$new_file
            fi

        done
    done

    flag_do_psi="no"
    for y in $( seq $diag_beg_year $diag_end_year ); do
        for m in $( seq 1 12 ); do
            if [ ! -f $( printf "$concat_dir/$casename.cam_extra3_streamfunction.h0.%04d-%02d.nc" $y $m ) ]; then
                flag_do_psi="yes"
                break
            fi
        done
        
        if [ "$flag_do_psi" == "yes" ]; then
            echo "Missing some streamfunction files. Do transforming..."
            break
        fi
    done

    if [ "$flag_do_psi" == "yes" ]; then
        julia $script_analysis_dir/streamfunction.jl --input-data-file-prefix="$concat_dir/$casename.cam_extra2_zonal_mean.h0." --output-data-file-prefix="$concat_dir/$casename.cam_extra3_streamfunction.h0." --domain-file=$atm_domain --beg-year=$diag_beg_year --end-year=$diag_end_year --V-varname=V
    fi

fi

