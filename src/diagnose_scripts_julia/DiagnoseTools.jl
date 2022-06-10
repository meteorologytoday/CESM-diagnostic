
module DiagnoseTools

    export DiagnoseEntry

    mutable struct DiagnoseEntry

        field  :: String   # atm, ocn, ice, ...
        label  :: String
        output :: Union{String, Function}
        func   :: Function

    end

end
