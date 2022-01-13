load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin

;****************************
; Déclaration des constantes
;****************************

  g=9.81
  nmo=1012
  nlev=17
  nx=144
  ny=96
  H=7594.29 ; constante de hauteur d'échelle (R* T* / g, avec R*=298 J/kg/K , T*=250K)
  pi=3.14159265
  omega=2*pi/86400.

;************************
; Ouverture du fichier
;************************

  f1  = "TP_TTT.nc" 
  in  = addfile(f1,"r")                              
  TP = in->TP 
  P = in->level
  latitude = in->latitude

  f2  = "U_TTT.nc" 
  in  = addfile(f2,"r")                              
  U = in->U 

  f3  = "V_TTT.nc" 
  in  = addfile(f3,"r")                              
  V = in->V

; Pressure in Pa
  P=P*100
  P0=100000.
; Log-pressure coordinates
  z=-H*log(P/P0) 

;********************************
; Calcul de la derivee dtheta/dz
;********************************
  
  dTP = new((/nmo,nlev,ny,nx/),"float")

  do k=0,nlev-1
  if (k.ne.0 .and. k.ne.nlev-1) then
  dTP(:,k,:,:)=(TP(:,k+1,:,:)-TP(:,k-1,:,:))/(z(k+1)-z(k-1))
  end if
  if (k.eq.0) then
  dTP(:,k,:,:)=(TP(:,k+1,:,:)-TP(:,k,:,:))/(z(k+1)-z(k))
  end if
  if (k.eq.nlev-1) then
  dTP(:,k,:,:)=(TP(:,k,:,:)-TP(:,k-1,:,:))/(z(k)-z(k-1))
  end if
  end do

;*********************************
; Calcul du N (Bouyancy frequency)
;********************************

  print ("Calcul du N")
  
  eps=0.0000001
  N=sqrt((g/TP)*dTP)+eps
  
;*********************************
; Calcul du paramètre de Coriolis
;*********************************

  lat_rad=latitude*pi/180.   ; fonction sin NCL->angle en radians
  copy_VarMeta(latitude,lat_rad)

  f=doubletofloat(2*omega*sin(lat_rad))
  copy_VarMeta(latitude,f)

  print("Calcul du paramètre de Coriolis")

;********************************
; Calcul de la derivee dU/dz
;********************************
  
  dU = new((/nmo,nlev,ny,nx/),"float")

  do k=0,nlev-1
  if (k.ne.0 .and. k.ne.nlev-1) then
  dU(:,k,:,:)=(U(:,k+1,:,:)-U(:,k-1,:,:))/(z(k+1)-z(k-1))
  end if
  if (k.eq.0) then
  dU(:,k,:,:)=(U(:,k+1,:,:)-U(:,k,:,:))/(z(k+1)-z(k))
  end if
  if (k.eq.nlev-1) then
  dU(:,k,:,:)=(U(:,k,:,:)-U(:,k-1,:,:))/(z(k)-z(k-1))
  end if
  end do

;************************************
; Calcul du maximum eady growth rate
;************************************
  
  print("Calcul du EGR")

  EGR=TP
  do j=0,ny-1
  EGR(:,:,j,:)=0.31*(f(j)/N(:,:,j,:))*dU(:,:,j,:)*86400  ; 86400 pour unite en /day
  end do
  copy_VarCoords(TP,EGR)

  print("Ecriture du fichier")

  system("/bin/rm EGR_TTT.nc")
  ncdf = addfile("EGR_TTT.nc","c")
  ncdf->EGR=EGR
  

end
