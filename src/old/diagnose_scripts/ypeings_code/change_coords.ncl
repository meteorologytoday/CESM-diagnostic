load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
begin

  fn= "VVV_TTT.nc"
  in = addfile(fn,"r")
  var = in->VVV 
               
   fn= "/seley/ypeings/simu/time_coord_TTT.nc"
  in = addfile(fn,"r")
  coord = in->SLP  
  
  var2=var
  delete(var2&time)

  var2!0 = "time"
  var2&time = coord&time
  
  system("/bin/rm VVV_TTT.nc")
  ncdf = addfile("VVV_TTT.nc","c")		
  ncdf->VVV = var2

end


