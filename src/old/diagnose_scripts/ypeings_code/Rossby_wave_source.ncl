load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin

; Rossby wave source, from Sardeshmukh and Hoskins (1988)
; Unites :  

;************************
; Ouverture des fichiers
;************************

f1  = "U200_TTT.nc" 
  in  = addfile(f1,"r")                              
  u = in->U200
  longitude = in->longitude
  latitude = in->latitude

f2  = "V200_TTT.nc" 
  in  = addfile(f2,"r")                              
  v = in->V200
  
print("Ouverture des fichiers")

;**************************************
; Calcul de la vorticite et divergence
;**************************************
  
  vort=u
  dv=u
  ud=u
  vd=u
  ur=u 
  vr=u
  uv2vrg (u,v,vort)           ; vorticity
  dv = uv2dv_cfd (u,v,latitude,longitude,3)             ; divergence
  dv2uvg   (dv,ud,vd)         ; ud and vd : divergent wind components

  print("Calcul de la vorticite relative et divergence")

;********************
; Coriolis parameter
;********************

  pi = atan(1.0)*4.
  f =  2.*2.*pi/(60.*60.*24.)*sin(pi/180. * dble2flt(latitude))
  f3d = conform_dims(dimsizes(u),f,1)
  copy_VarCoords(u,f3d)

  print("Coriolis parameter")

;***************
; Calcul du RWS
;***************

; Absolute vorticity
  absvort=vort+f3d  
  copy_VarCoords(vort,absvort) 

  absvort_grad_lon=absvort
  absvort_grad_lat=absvort
  gradsg(absvort,absvort_grad_lon,absvort_grad_lat)

  RWS=u
  RWS=-(dv*absvort)-(ud*absvort_grad_lon)-(vd*absvort_grad_lat)
  print("Calcul du RWS")

;************************
; Ecriture des fichiers
;************************

  system("/bin/rm RWS_TTT.nc")
  ncdf = addfile("RWS_TTT.nc","c")
  ncdf->RWS=RWS

end

