;*************************************************
; temp_potentielle.ncl
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
begin

;****************************
; Déclaration des constantes
;****************************

PO= 1000.
c_pd = 1004.    ; specific heat at constant pressure for air [approx 1004 J/(kg-K)]
R = 287.        ; specific gas constant for air [J/(kg-K)]
Rcpd = R/c_pd

;************************
; Ouverture du fichier
;************************

f1  = "TEMP_1900-2000.nc" 
   in  = addfile(f1,"r")                              
   T = in->TEMP
;   T2=short2flt(T)
;   copy_VarCoords(T,T2)
;   delete(T)
;   T=T2+273.16
;   copy_VarCoords(T2,T)
;   delete(T2)

print("Ouverture du fichier")

;**************************************
; Calcul de la température potentielle
;**************************************

theta = new((/17,1212,96,144/),"float")
P=(/1000.,925.,850.,700.,600.,500.,400.,300.,250.,200.,150.,100.,70.,50.,30.,20.,10./)

T2=T(level|:,time|:,latitude|:,longitude|:)

do i=0,16
theta(i,:,:,:)=T2(i,:,:,:)*((PO/P(i))^Rcpd)
end do

theta!0 = "level"  
theta!1 = "time"
theta!2 = "latitude"
theta!3 = "longitude"

print("Calcul des températures potentielles")

;************************
; Ecriture des fichiers
;************************

theta2=theta(time|:,level|:,latitude|:,longitude|:)
copy_VarCoords(T,theta2)

system("/bin/rm TP_1900-2000.nc")
ncdf = addfile("TP_1900-2000.nc","c")
setfileoption("ncdf","Format","LargeFile")
filedimdef(ncdf,"time",-1,True) 
ncdf->TP=theta2



end
