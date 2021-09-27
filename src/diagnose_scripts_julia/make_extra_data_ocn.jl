using ArgParse
using Formatting
using JSON,TOML
using DataStructures

include("runCmd.jl")

s = ArgParseSettings()
@add_arg_table s begin
     
    "--casename"
        help = "Prefix of the file."
        arg_type = String
        required = true

    "--input-dir"
        help = "The folder where case folders are contained"
        arg_type = String
        required = true

    "--output-dir"
        help = "Output folder"
        arg_type = String
        required = true

    "--year-rng"
        help = "Range of years being diagnosed"
        arg_type = Int64
        nargs = 2
        required = true

    "--domain-file"
        help = "Domain file of sea ice model"
        arg_type = String
        required = true

    "--overwrite"
        action = :store_true
 
    "--remap-file-nn"
        help = "Remap weighting file"
        arg_type = String
        required = true

  
end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)


for y = parsed["year-rng"][1]:parsed["year-rng"][2], m=1:12
 
    date_str = format("{:04d}-{:02d}", y, m)

    old_file  = joinpath(parsed["input-dir"],  "$(parsed["casename"]).EMOM.h0.mon.$(date_str).nc")
    new_file1 = joinpath(parsed["output-dir"], "$(parsed["casename"]).EMOM_extra1.$(date_str).nc")
    new_file2 = joinpath(parsed["output-dir"], "$(parsed["casename"]).EMOM_extra1_rg.$(date_str).nc")
    
    if !isfile(new_file1) || !isfile(new_file2) || parsed["overwrite"]
        
        println("Generating file: $(new_file1)")
        pleaseRun(`ncap2 -h -O -v 
                    -s 'SST=array(0.0,0.0,/$time,$Ny,$Nx/);  SST(0,:,:)=TEMP(0, 0, :, :);'
                    -s '*tmp=HMXL*1.0;'
                    -s 'HMXL=array(0.0,0.0,/$time,$Ny,$Nx/); HMXL(0,:,:)=tmp(0,0,:,:);'
                    $old_file $new_file1
        `; igs=true)
        println("Generating file: $(new_file2)")
        pleaseRun(`ncremap -R '--rgr lat_nm_in=Ny --rgr lon_nm_in=Nx' -m $(parsed["remap-file-nn"]) $new_file1 $new_file2`;igs=true)    

    end
   
    # Special: stratification 
    new_file3 = joinpath(parsed["output-dir"], "$(parsed["casename"]).EMOM_extra2.$(date_str).nc")
    if !isfile(new_file3) || parsed["overwrite"]
        
        println("Generating file: $(new_file1)")
        pleaseRun(`ncap2 -h -O -v 
                    -s 'defdim("Nz1", 5); defdim("Nz2", 28);'
                    -s '*dz = dz_cT(:, 0, 0); *dz1=dz(0:4).ttl(); *dz2=dz(5:32).ttl();'
                    -s '*TEMPdz[$time,$Nz,$Ny,$Nx]=TEMP*dz; TEMPdz.set_miss(TEMP@_FillValue)'
                    -s '*_T1=array(0.0,0.0,/$time,$Nz1,$Ny,$Nx/);_T1.set_miss(TEMP@_FillValue);'
                    -s '*_T2=array(0.0,0.0,/$time,$Nz2,$Ny,$Nx/);_T2.set_miss(TEMP@_FillValue);'
                    -s '_T1(:, :, :, :)=TEMPdz(:, 0:4, :, :);'
                    -s '_T2(:, :, :, :)=TEMPdz(:, 5:32, :, :);'
                    -s 'T1=_T1.ttl($Nz1)/dz1;'
                    -s 'T2=_T2.ttl($Nz2)/dz2;'
                    -s 'STRAT=T1-T2;'
                    $old_file $new_file3
        `; igs=true)
    end
 
end
