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

    old_file  = joinpath(parsed["input-dir"],  "$(parsed["casename"]).cice.h.$(date_str).nc")
    new_file1 = joinpath(parsed["output-dir"], "$(parsed["casename"]).cice_extra1.$(date_str).nc")
    new_file2 = joinpath(parsed["output-dir"], "$(parsed["casename"]).cice_extra2_rg.$(date_str).nc")
    
    if !isfile(new_file1) || !isfile(new_file2) || parsed["overwrite"]
        
        println("Generating file: $(new_file1)")
        pleaseRun(`ncap2 -h -O -v 
                    -s 'vice=vicen001+vicen002+vicen003+vicen004+vicen005;' 
                    -s 'aice=(aicen001+aicen002+aicen003+aicen004+aicen005)/100.0;'
                    $old_file $new_file1
        `)
        
        println("Generating file: $(new_file2)")
        pleaseRun(`ncremap -v aice,vice -m $(parsed["remap-file-nn"]) $new_file1 $new_file2`)    
    end

end
