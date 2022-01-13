load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin

; Divergent component of the wind 
; Unites : m/s 

;************************
; Ouverture des fichiers
;************************

f1  = "U_TTT.nc" 
  in  = addfile(f1,"r")                              
  u = in->U
  longitude = in->longitude
  latitude = in->latitude

f2  = "V_TTT.nc" 
  in  = addfile(f2,"r")                              
  v = in->V
  
print("Ouverture des fichiers")

;*************************
; Calcul de la divergence
;*************************
  
  ud=u
  vd=u
  dv = uv2dv_cfd (u,v,latitude,longitude,3)             ; divergence
  dv2uvg   (dv,ud,vd)         ; ud and vd : divergent wind components

  print("Calcul de la divergence")

;************************
; Ecriture des fichiers
;************************

  system("/bin/rm DU_TTT.nc")
  ncdf = addfile("DU_TTT.nc","c")
  ncdf->DU=ud

  system("/bin/rm DV_TTT.nc")
  ncdf = addfile("DV_TTT.nc","c")
  ncdf->DV=vd

end

