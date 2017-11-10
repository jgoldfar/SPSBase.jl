using SPS
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@testset "SPS" begin

include("UIObjects.jl")

include("UIObjectsSupport.jl")

include("LowLevel.jl")

end # testset