VERSION >= v"0.4.0-dev+6521" && __precompile__()
module SPSBase

include("UIObjects.jl")

include("UIObjectsSupport.jl")

include("LowLevel.jl")

function generateFunctional(bsl::BitScheduleList, baseWeightVec::Vector{Float64}, adjBenefit::Real = 0.1)
    adjMat = to_adjacency_mat(bsl)
    times = bsl.times
    function J(v::BitVector)
        internalWeights = copy(baseWeightVec)
        J1 = 0.0
        J2 = 0.0
        @inbounds for (vi, vv) in enumerate(v)
            if vv
                J1 += internalWeights[vi]

                # Reduce benefit for scheduling another person at the same time
                currTime = times[vi]
                for (ti, tv) in enumerate(times)
                    if tv == currTime
                        internalWeights[ti] -= 1
                    end
                end

                # Add benefit for scheduling a person at an adjacent time
                J2 += sum(adjMat[vi, :].*v)*adjBenefit
            end
        end
        J1 + J2
    end
    J
end

function generateFunctionalAndControlVector(el::EmployeeList, baseWeightVec::Vector{Float64}, increment::Real = 1, adjBenefit::Real = 0.1)
    bsl = BitScheduleList(el, increment)
    J = generateFunctional(bsl, baseWeightVec, adjBenefit)
    J, bsl
end
function generateFunctionalAndControlVector(el::EmployeeList, increment::Real = 1, adjBenefit::Real = 0.1)
    bsl = BitScheduleList(el, increment)
    nv = length(bsl.vec)
    np = length(el)
    J = generateFunctional(bsl, np*ones(Float64, nv), adjBenefit)
    J, bsl
end
include("precompile.jl")

end