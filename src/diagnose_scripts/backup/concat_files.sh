#!/bin/bash



outputfile=$nc_output_dir/$casename.atm.h0.nc

if [ -f $outputfile ]; then

    echo "No need to concat atm files."
    echo "$outputfile already exists."

else

    printf "Concat atmospheric files... "
        # atm variables
    cd $atm_hist_path 
    eval $(cat <<EOF
    ncrcat -O -v ilev,PSL,V,TREFHT,VQ,VZ,VT,PRECC,PRECL,FSNT,FSNS,FLNT,FLNS,SHFLX,LHFLX $casename.cam.h0.{$beg_year..$end_year}-{01..12}.nc $nc_output_dir/$casename.h0.nc

    #ncrcat -O -v ilev,TREFHT $in_dir/$casename.cam.h1.00{01..20}-01-01-00000.nc $nc_output_dir/$casename.h1.nc



EOF
    )
    cd $wpath

    printf "done.\n"

fi
