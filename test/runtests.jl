using SPSBase
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@testset "SPSBase" begin

include("UIObjects.jl")

include("UIObjectsSupport.jl")

include("LowLevel.jl")

@testset "Main" begin
    nEmployees = 4
    emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
    emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), Inf, nEmployees + 1)
    employees = push!(
        [Employee("Limited $i", emp2sched, Inf, i) for i in 1:nEmployees],
        emp3
    )
    schedulingResolution = 1//2

    J, bsl = SPSBase.generateFunctionalAndControlVector(employees, schedulingResolution)

    @testset "generateEmployeeMat" begin

        indRanges = SPSBase.getEmployeeIndices(bsl)
        indMat = SPSBase.generateEmployeeMat(bsl)
        indMatStructureCorrect = true
        for (i, inds) in enumerate(indRanges)
            indMatStructureCorrect = indMatStructureCorrect && 
            all(isapprox(v, 1) for v in indMat[inds, inds]) &&
            all(isapprox(v, 0) for v in indMat[inds, (last(inds)+1):end]) && 
            all(isapprox(v, 0) for v in indMat[(last(inds)+1):end, inds])
        end
        @test indMatStructureCorrect
    end

    @testset "generateFunctionalAndControlVector" begin    
        nv = length(bsl.vec)
        @test typeof(J) <: Function
        @test typeof(bsl) <: SPSBase.BitScheduleList

        bslv = falses(nv)
        @test isapprox(J(bslv), 0)
        
        bslv[1] = true
        JWith1True = J(bslv)
        @test JWith1True > 0

        bslv[1] = true
        bslv[2] = true
        JWith2True = J(bslv)
        @test JWith2True > JWith1True

        bslv[1] = true
        bslv[2] = false
        bslv[5] = true # Coincides with bslv[1]
        @test JWith2True > J(bslv) > JWith1True

        bslv[1] = true
        bslv[2] = true
        bslv[5] = false
        JWithAdjacentTrue = J(bslv)
        bslv[2] = false
        bslv[3] = true
        JWithNonAdjacentTrue = J(bslv)
        @test JWithAdjacentTrue > JWithNonAdjacentTrue

    end
end
end # testset