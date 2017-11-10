using SPS
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@testset "UIObjects" begin

# Setup
emp1sched = Schedule(
[(8, 10), (12, 15), (18, 20)],
[(8, 10), (12, 15)],
[(9, -2), (10, 12)],
[(9, 17)],
[(9, 9), (13, 16)]
)
emp1 = Employee("Max", emp1sched, 0)

schedulingResolution = 1//2

@testset "Basic Schedule/Employee Functionality" begin
    @test Schedule(emp1) == emp1sched
    @testset "Generate Employee($T) with empty Schedule" for T in (Int, Float64, Rational{Int})
        @test isempty(SPS.emptySchedule(T))
        tmpEmp = Employee(string(T), SPS.emptySchedule(T), 1)
        @test typeof(tmpEmp) <: Employee{T}
        @test isempty(Schedule(tmpEmp))
    end
    @testset "Schedule clamping" begin
    osched = [
        (9, 19),
        (8, 19),
        (9, 16),
        (8, 19),
        (9, 16)
    ]
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

@testset "EmployeeList" begin
    # An EmployeeList is just a list of employees...

    emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
    emp2 = Employee("Limited", emp2sched, 0)

    employees = [emp1, emp2]
    @test isa(employees, EmployeeList)
end
end # testset