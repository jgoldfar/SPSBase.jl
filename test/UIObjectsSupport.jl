using SPSBase
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@testset "UIObjectsSupport" begin

emp1sched = Schedule(
[(8, 10), (12, 15), (18, 20)],
[(8, 10), (12, 15)],
[(9, -2), (10, 12)],
[(9, 17)],
[(9, 9), (13, 16)]
)

@testset "Basic Schedule/Employee Functionality" begin
    @test eltype(emp1sched) == typeof((8, 10)) # Each element should have the same type as the input
    @test !SPSBase._isvalid_block((9, -2)) && !SPSBase._isvalid_block((9, 9))
    @test SPSBase._isvalid_block((8, 10))
    @test length(emp1sched) == 8 # Invalid times should be filtered out.
    @test first(emp1sched) == (8, 10) # Iteration is defined
    iterationsCompleted = 0
    for time in emp1sched
        iterationsCompleted += 1
    end
    @test iterationsCompleted == length(emp1sched) # Iteration also works in for loop

    @test emp1sched[3] == (18, 20) # Supports indexing
    @test emp1sched[end] == (13, 16) # Supports [end] syntax
    @test_throws BoundsError emp1sched[9] # Supports bounds check
    
    @test length(SPSBase._to_iter(emp1sched)) == 5 # Test lazy conversion to iterator

    @test SPSBase.t_min([(1,1), (9, 17), (0, 5), (8, 20), (20, 25)], (9, 17)) == [(9, 17), (9, 17)]
end

end # testset