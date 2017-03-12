using SPS
using Base.Test


const osched = [
    (9, 19),
    (8, 19),
    (9, 19),
    (8, 19),
    (9, 16)
]
const emp1sched = Schedule(
[(9, 17)],
[(9, 17)],
[(9, 17)],
[(9, 17)],
[(9, 17)]
)
const emp1 = Employee("Max", emp1sched, 0)

println(SPS.to_vec(emp1sched, 1//4))

println(SPS.s_min(emp1sched, osched))

println(emp1)
