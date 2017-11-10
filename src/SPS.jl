VERSION >= v"0.4.0-dev+6521" && __precompile__()
module SPS

include("UIObjects.jl")

include("UIObjectsSupport.jl")

include("LowLevel.jl")

function generateFunctional(el::EmployeeList)

end

include("precompile.jl")

end