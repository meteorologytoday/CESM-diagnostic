load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
begin

  fn= "VVV_TTT.nc"
  in = addfile(fn,"r")
  T = in->VVV 

  T_grad_lon = T                ; create arrays to hold output, same size and type as input
  T_grad_lat = T                
                                ; this procedure will overwrite
                                ; values in T_grad_lon and T_grad_lat
                                
  gradsf (T, T_grad_lon, T_grad_lat)   

  T_grad_lon@long_name = "longitudinal gradient (derivative)"
  T_grad_lat@long_name = "latitudinal gradient (derivative)"
  T_grad_lat@units     = "C/100km"
  T_grad_lon@units     = "C/100km"

; En deg/km (et non m)
  T_grad_lon = T_grad_lon*100000.
  T_grad_lat = T_grad_lat*100000.
  
  copy_VarCoords(T,T_grad_lon)
  copy_VarCoords(T,T_grad_lat)

  system("/bin/rm VVVgradx_TTT.nc")
  ncdf = addfile("VVVgradx_TTT.nc","c")		
  ncdf->VVVgradx = T_grad_lon
  
  system("/bin/rm VVVgrady_TTT.nc")
  ncdf = addfile("VVVgrady_TTT.nc","c")		
  ncdf->VVVgrady = T_grad_lat

              
end


