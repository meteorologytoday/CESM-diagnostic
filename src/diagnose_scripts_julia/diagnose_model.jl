using ArgParse
using Formatting
using JSON,TOML
using DataStructures

include("runCmd.jl")

s = ArgParseSettings()
@add_arg_table s begin
    "--diag-file"
        help = "The TOML file containing the information to diagnose."
        arg_type = String
        required = true
end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)
#=
    "--casename"
        help = "Casename"
        arg_type = String
        required = true

    "--root"
        help = "The folder where case folders are contained"
        arg_type = String
        required = true

    "--year-rng"
        help = "Range of years being diagnosed"
        arg_type = Int64
        nargs = 2
        required = true

    "--cesm-env"
        help = "The TOML file used to set env_mach_pes.xml, env_run.xml"
        arg_type = String
        default = ""

    "--build"
        help = "If set then will try to build the case."
        action = :store_true
=#


cfg = TOML.parsefile(parsed["diag-file"]) |> DataStructures.OrderedDict
println("Loaded diagnose configuration file ", parsed["diag-file"])
JSON.print(cfg, 4)

result_dir = "result"
diag_data_dir = joinpath(result_dir, cfg["diag-label"])
mkpath(result_dir)
mkpath(diag_data_dir)

for (diagset_name, diagset) in cfg["diagsets"]

    println("Diagset detail: ")
    JSON.print(diagset, 4)

    extra_data_dir = joinpath(result_dir, "extra_data", diagset["casename"])
    mkpath(extra_data_dir)

    hist_dir_atm = joinpath(cfg["archive-root"], diagset["casename"], "atm", "hist")

    pleaseRun(`julia $(@__DIR__)/make_extra_data_atm.jl
        --casename   $(diagset["casename"])
        --input-dir  $(hist_dir_atm)
        --output-dir $(extra_data_dir)
        --year-rng   $(diagset["year-rng"][1]) $(diagset["year-rng"][2])
        --domain-file $(cfg["domains"]["atm"])
    `)
end
