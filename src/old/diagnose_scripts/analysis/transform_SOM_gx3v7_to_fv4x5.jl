include(joinpath(@__DIR__, "..", "CoordTrans", "CoordTrans.jl"))

using .CoordTrans

if length(ARGS) == 3
    in_filename = ARGS[1]
    out_filename = ARGS[2]
    wgt_filename = ARGS[3]
else
    println("ARGS does not equal to 3. Maybe parameters have been set already. Keep going...")
end



CoordTrans.convertFile(
    in_filename,
    out_filename,
    wgt_filename,
    varnames=("T_ML",);
    xdim = "Nx",
    ydim = "Ny",
    tdim = "time",
)
