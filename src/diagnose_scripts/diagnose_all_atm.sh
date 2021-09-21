#!/bin/bash

casename="lowres_SSM_SOM"
p="$casename/SSM_OCN/ocn/"


i_beg=1
i_end=20

flist=""

for yr in $(seq $i_beg $i_end) ; do
    printf "Processing year %02d \n" $yr

    gxfile=$p/$(printf "$casename.xttocn_SOM.h.%04d.nc" $yr)
    ma_gxfile=$p/$(printf "$casename.xttocn_SOM.h.ma.%04d.nc" $yr)
    ma_fvfile=$p/$(printf "$casename.xttocn_SOM.h.ma.fv4x5.%04d.nc" $yr)

    if [ ! -f "$ma_gxfile" ]; then
        ncra -O -d time,,,30 --mro $gxfile $ma_gxfile
    fi

    if [ ! -f "$ma_fvfile" ]; then
        julia diagnose_scripts/transform_gx3v7_to_fv4x5.jl $ma_gxfile $ma_fvfile
    fi
    
    flist="$flist $ma_fvfile"
done


ncrcat -O $flist $(printf "$casename.xttocn_SOM.h.ma.fv4x5.%04d-%04d.nc" $i_beg $i_end)

#rm $p/*.ma.*
