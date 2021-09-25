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
        help = "Domain file of atmosphere"
        arg_type = String
        required = true


    "--overwrite"
        action = :store_true
   
end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)


for y = parsed["year-rng"][1]:parsed["year-rng"][2], m=1:12
 
    date_str = format("{:04d}-{:02d}", y, m)

    old_file = joinpath(parsed["input-dir"], "$(parsed["casename"]).cam.h0.$(date_str).nc")

    new_file1 = joinpath(parsed["output-dir"], "$(parsed["casename"]).cam_extra1.$(date_str).nc")
    if !isfile(new_file1) || parsed["overwrite"]
        println("Generating file: $(new_file1)")
        pleaseRun(`ncap2 -h -O -v -s 'PREC_TOTAL=PRECC+PRECL;' $old_file $new_file1`)
    end

    new_file2 = joinpath(parsed["output-dir"], "$(parsed["casename"]).cam_extra2_zmean.$(date_str).nc")
    if !isfile(new_file2) || parsed["overwrite"]
        println("Generating file: $(new_file2)")
        pleaseRun(`ncwa -O -a lon -v T,U,V,ilev $old_file $new_file2`)
    end

end
       
println("Diagnose streamfunction") 
pleaseRun(`julia $(@__DIR__)/lib/streamfunction.jl 
    --input-data-file-prefix $(parsed["output-dir"])/$(parsed["casename"]).cam_extra2_zmean.
    --output-data-file-prefix $(parsed["output-dir"])/$(parsed["casename"]).cam_extra3_streamfunction.
    --domain-file $(parsed["domain-file"])
    --beg-year $(parsed["year-rng"][1])
    --end-year $(parsed["year-rng"][2])
    --V-varname V
`)



