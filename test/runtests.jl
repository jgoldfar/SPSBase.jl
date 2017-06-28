using SPS
using Base.Test


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
@test first(emp1sched) == (8, 10) # Iteration is defined?
@test emp1sched[3] == (18, 20) # Supports indexing
@test emp1sched[end] == (13, 16) # Supports [end] syntax
@test Schedule(emp1) == emp1sched

println(SPS.s_min(emp1sched, osched))

println(emp1)
