load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin

   in  = addfile("u.nc","r")                              
   u = in->U

   in  = addfile("v.nc","r")                              
   v = in->V
  
   sf = u
   vp = u
   uv2sfvpg (u,v, sf,vp)

   system("/bin/rm SFLLL_TTT.nc")
   ncdf = addfile("SFLLL_TTT.nc","c")
   ncdf->SFLLL = sf

   system("/bin/rm PVLLL_TTT.nc")
   ncdf = addfile("PVLLL_TTT.nc","c")
   ncdf->PVLLL = vp

end
