using DataStructures

archive_root = "/glade/scratch/tienyiao/archive"
output_dir = "output"
domain_files = Dict(
    "ice" => "CESM_domains/domain.ocn.gx1v6.090206.nc",
    "ocn" => "CESM_domains/domain.ocn.gx1v6.090206.nc",
)


cases = OrderedDict(

    "qco2_SOM" => Dict(
        "model" => "SOM",
        "yrng" => [201, 400],
    ),

    "qco2_MLM" => Dict(
        "model" => "MLM",
        "yrng" => [201, 500],
    ),

    "qco2_EMOM" => Dict(
        "model" => "EMOM",
        "yrng" => [201, 500],
    ),

    "qco2_POP2" => Dict(
        "model" => "POP2",
        "yrng" => [  1, 600],
    ),
)
casenames = keys(cases)
