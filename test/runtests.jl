using SPS
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@testset "SPS" begin

# Setup
osched = [
    (9, 19),
    (8, 19),
    (9, 16),
    (8, 19),
    (9, 16)
]
emp1sched = Schedule(
[(8, 10), (12, 15), (18, 20)],
[(8, 10), (12, 15)],
[(9, -2), (10, 12)],
[(9, 17)],
[(9, 9), (13, 16)]
)
emp1 = Employee("Max", emp1sched, 0)

emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
emp2 = Employee("Limited", emp2sched, 0)

schedulingResolution = 1//2

@testset "Basic Schedule/Employee Functionality" begin
    @test eltype(emp1sched) == typeof((8, 10)) # Each element should have the same type as the input
    @test length(emp1sched) == 8 # Invalid times should be filtered out.
    @test first(emp1sched) == (8, 10) # Iteration is defined
    @test emp1sched[3] == (18, 20) # Supports indexing
    @test emp1sched[end] == (13, 16) # Supports [end] syntax
    @test Schedule(emp1) == emp1sched

    @testset "Schedule clamping" begin
    # s_min clamps the given schedule to the overall schedule osched
    emp1schedmin = SPS.s_min(emp1sched, osched)
    @test length(emp1schedmin.day1) == length(emp1sched.day1)
    @test first(emp1schedmin.day1[1]) == first(osched[1])
    end

    @testset "schedules_isapprox" begin
    # schedules_isapprox tests approximate equality. The schedule below is too distinct from emp1sched.
    emp1schedDifferent = Schedule(
        [(8.1, 10.0), (12.0, 15.0), (18.0, 20.0)],
        [(7.9, 10.0), (12.0, 15.0)],
        [(9.0, -2.0), (10.0, 12.0)],
        [(9.0, 17.0)],
        [(9.0, 9.0), (13.0, 16.0)]
        )
    @test !SPS.schedules_isapprox(emp1sched, emp1schedDifferent)

    # emp1schedFloat is indistinguishable from emp1sched
    emp1schedFloat = Schedule(
        [(8.0, 10.0), (12.0, 15.0), (18.0, 20.0)],
        [(8.0+eps(8.0)/2, 10.0), (12.0, 15.0)],
        [(9.0, -2.0), (10.0, 12.0 - eps(12.0)/2)],
        [(9.0, 17.0)],
        [(9.0, 9.0), (13.0, 16.0)]
        )
    @test SPS.schedules_isapprox(emp1sched, emp1schedFloat)
    end
end

@testset "Vectorization and Unvectorization" begin
    # Filling all of an employee's time makes to_vec and to_sched inverse functions when operating on Schedule objects
    emp1schedVec = SPS.to_vec(emp1sched, schedulingResolution)
    fill!(emp1schedVec, true)
    @test SPS.schedules_isapprox(SPS.to_sched(emp1sched, emp1schedVec, schedulingResolution), emp1sched)
    
    emp2schedVec = SPS.to_vec(emp2sched, schedulingResolution)
    fill!(emp2schedVec, true)
    @test SPS.schedules_isapprox(SPS.to_sched(emp2sched, emp2schedVec, schedulingResolution), emp2sched)
    
    # Test that to_Vec works with an Employee object
    emp2Vec = SPS.to_vec(emp2, schedulingResolution)
    fill!(emp2Vec, true)
    @test emp2schedVec == emp2Vec
    # Same invariant as with the underlying schedule object
    @test SPS.schedules_isapprox(Schedule(SPS.to_sched(emp2, emp2Vec, schedulingResolution)), emp2sched)
    @test length(emp2Vec) == length(emp2schedVec)
    @test length(emp2Vec) == 4
    # Doubling the resolution doubles the number of elements
    @test length(SPS.to_vec(emp2sched, 1//4)) == 2*length(SPS.to_vec(emp2sched, 1//2))
end
# @testset "Schedule Weights" begin
#     #TODO: Re-add this functionality
#     emp1weights = ScheduleWeights([1, 2, 3], [3, 2], [1, 1], [0], [-2, -4])
#     @test SPS.isvalid(emp1sched, emp1weights)
# end

@testset "EmployeeList" begin
    # An EmployeeList is just a list of employees...
    employees = [emp1, emp2]
    @test isa(employees, EmployeeList)

    # Test vectorizationof a list of employees
    employeesVec = SPS.to_vec(employees, schedulingResolution)
    fill!(employeesVec, true)

    # The length of the vectorized employeelist should be the sum of the lengths of its member vectors
    @test length(employeesVec) == length(SPS.to_vec(emp2, schedulingResolution)) + length(SPS.to_vec(emp1, schedulingResolution))

    # to_vec and to_sched are nearly inverse functions
    employeeSchedules = SPS.to_sched(employees, employeesVec, schedulingResolution)
    for (i, v) in enumerate(employees)
        @test SPS.schedules_isapprox(Schedule(employeeSchedules[i]), Schedule(v))
        @test employeeSchedules[i].name == v.name && employeeSchedules[i].specialty == v.specialty
    end
end
end # testset