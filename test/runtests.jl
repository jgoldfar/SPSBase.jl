using SPS
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end


const osched = [
    (9, 19),
    (8, 19),
    (9, 16),
    (8, 19),
    (9, 16)
]
const emp1sched = Schedule(
[(8, 10), (12, 15), (18,20)],
[(8, 10), (12, 15)],
[(9, -2), (10, 12)],
[(9, 17)],
[(9, 9), (13, 16)]
)
const emp1 = Employee("Max", emp1sched, 0)
@test eltype(emp1sched) == typeof((8, 10))
@test length(emp1sched) == 10
@test first(emp1sched) == (8, 10) # Iteration is defined
@test emp1sched[3] == (18, 20) # Supports indexing
@test emp1sched[end] == (13, 16) # Supports [end] syntax
@test Schedule(emp1) == emp1sched

const emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
const emp2 = Employee("Limited", emp2sched, 0)
@test length(SPS.to_vec(emp2sched, 1//2)) == 4
@test length(SPS.to_vec(emp2sched, 1//4)) == 2*length(SPS.to_vec(emp2sched, 1//2))
@test length(SPS.to_vec(emp2, 1//2)) == length(SPS.to_vec(emp2sched, 1//2))

const emp1schedmin = SPS.s_min(emp1sched, osched)
@test length(emp1schedmin.day1) == length(emp1sched.day1)
@test first(emp1schedmin.day1[1]) == first(osched[1])

const emp1weights = ScheduleWeights([1, 2, 3], [3, 2], [1, 1], [0], [-2, -4])
@test SPS.isvalid(emp1sched, emp1weights)

const employees = [emp1, emp2]
@test isa(employees, EmployeeList)
@test length(SPS.to_vec(employees, 1//2)) == length(SPS.to_vec(emp2, 1//2)) + length(SPS.to_vec(emp1, 1//2))
