load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin

   f1  = "GEOP_TTT.nc" 
   in  = addfile(f1,"r")                              
   z = in->GEOP

;   z2=rmMonAnnCycTLL(z)
;   copy_VarCoords(z,z2)

   z3=dim_rmvmean(z(time|:, level|:, latitude|:, longitude|:))
   copy_VarCoords(z,z3)


    system("/bin/rm GEOPx_TTT.nc")
    ncdf = addfile("GEOPx_TTT.nc","c")
    ncdf->GEOPx = z3



end
