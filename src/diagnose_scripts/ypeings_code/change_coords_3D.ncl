load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;**************************************
begin
;****************************************

; Interpolate from hybrid coordinates of WACCM4 (66 levels) to 17 pressure levels

  fn= "EXP_TTT.nc"
  in = addfile(fn,"r")
  var = in->VVV
  hyam = in->hyam  ; coeff coordonnes hybrides
  hybm = in->hybm
  psur = in->PS  ; surface pressure 
  gsur = in->PHIS  ; surface geopotential
  T = in->T 

  ; surface temperature (lowest level of T)
  nlev=66
  tsur=T(:,nlev-1,:,:)
               
  plev           = (/  10, 20, 30, 50, 70,100,150,200,250 \
                     , 300,400,500,600,700,850,925,1000 /)            
  plev!0         = "level"                  ; variable/dim name 
  plev&level     =  plev                   ; create coordinate variable
  plev@long_name = "Pressure"               ; attach some attributes
  plev@units     = "hPa"
  plev@positive  = "down"
  P0mb = 1000. 
  intyp = 1  ; Type  of interpolation

; Interpolate under ground level
  varname="VVV"
  if (varname .eq. "Z3" ) then
  varflg = -1 
  else if (varname .eq. "T" ) then
  varflg = 1
  else
  varflg = 0
  end if
  end if

  var2   = vinth2p_ecmwf(var, hyam, hybm, plev, psur, intyp, P0mb, 1, True, varflg, tsur, gsur )

; Change of the time coordinate  

  fn= "/seley/ypeings/simu/time_coord_TTT.nc"
  in = addfile(fn,"r")
  coord = in->SLP(:,:,:) 

  delete(var2&time)
  var2!0 = "time"
  var2&time = coord&time
  
  system("/bin/rm VV2_TTT.nc")
  ncdf = addfile("VV2_TTT.nc","c")		
  ncdf->VV2 = var2(:,::-1,:,:)

end


