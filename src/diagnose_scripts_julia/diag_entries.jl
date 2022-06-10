include("DiagnoseTools.jl")
using .DiagnoseTools

diag_entries = Dict()

function _addEntry(d, diag_entry)
    if haskey(d, diag_entry.label)
        throw(ErrorException("Entry label `$(diag_entry.label)` already exists."))
    end
    d[diag_entry.label] = diag_entry
end

function addDiagnoseEntry(diag_entry :: DiagnoseEntry)
    global diag_entries
    _addEntry(diag_entries, diag_entry)
end

include("diag_atm.jl")
include("diag_ocn.jl")
include("diag_ice.jl")
