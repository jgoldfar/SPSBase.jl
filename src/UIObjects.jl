export Schedule
"""
    Schedule(day1, day2, day3, day4, day5)

A schedule is a relatively easy-to-write form of either an availability schedule
or collection of times scheduled; each `day` is a Vector of Tuples of Numbers 
representing the start and end times.

`Schedule`s admit an iterator interface (that is, they can be indexed into, have a
specified length, etc.)

## Example ##
```julia
emp1sched = Schedule(
    [(8, 10), (12, 15), (18, 20)], # Day 1 Availability
    [(8, 10), (12, 15)], # Day 2 Availability
    [(9, -2), (10, 12)], # Day 3 Availability
    [(9, 17)], # Day 4 Availability
    [(9, 9), (13, 16)] # Day 5 Availability
    )
```

Note: the time intervals `(9,-2)` and `(9,9)` are invalid and will be filtered out
from the constructed `Schedule` object. So, for instance,

```
emp1sched.day5 == [(13, 16)] # true
```
"""
struct Schedule{T<:Number}
    day1::Vector{Tuple{T, T}}
    day2::Vector{Tuple{T, T}}
    day3::Vector{Tuple{T, T}}
    day4::Vector{Tuple{T, T}}
    day5::Vector{Tuple{T, T}}

    function Schedule(day1::Vector{Tuple{T, T}}, day2::Vector{Tuple{T, T}}, day3::Vector{Tuple{T, T}}, day4::Vector{Tuple{T, T}}, day5::Vector{Tuple{T, T}}) where {T <: Number}
        new{T}(
            filter(_isvalid_block, day1),
            filter(_isvalid_block, day2),
            filter(_isvalid_block, day3),
            filter(_isvalid_block, day4),
            filter(_isvalid_block, day5)
        )
    end
end

"""
`Schedule` objects can also be created using a `Dict`, which
allows more ergonomic creation of sparse schedules.

## Example ##
```
SPSBase.Schedule(
    Dict(:day1 => [(9,9)], :day4 => [(10, 13), (16, 21)])
    )
```
"""
function Schedule(days::Dict{Symbol, Vector{Tuple{T, T}}}) where {T<:Number}
    Schedule(
        get(days, :day1, Tuple{T, T}[]),
        get(days, :day2, Tuple{T, T}[]),
        get(days, :day3, Tuple{T, T}[]),
        get(days, :day4, Tuple{T, T}[]),
        get(days, :day5, Tuple{T, T}[])
    )
end

# function Schedule(;
#     args...,)
#     # day1::Vector{Tuple{T, T}} = Tuple{T,T}[], day2::Vector{Tuple{T, T}} = Tuple{T,T}[], day3::Vector{Tuple{T, T}} = Tuple{T,T}[], day4::Vector{Tuple{T, T}} = Tuple{T,T}[], day5::Vector{Tuple{T, T}} = Tuple{T,T}[])
#     # Schedule(day1, day2, day3, day4, day5)
#     outputType = UInt8
#     for (name, argv) in args
#         if name in (:day1, :day2, :day3, :day4, :day5)
#             argv_eltype = eltype(argv)
#             if !(argv_eltype <: Tuple{T, T} where {T<:Number})
#                 error("Unable to construct Schedule with argument $(name) of type $(argv_eltype)")
#             end
#             outputType = promote_type(outputType, eltype(argv_eltype))
#             @show outputType
#             @show argv
#         end
#     end
#     return emptySchedule(Int)
# end

"""
    emptySchedule(T)

Construct a `Schedule` object with elements of numeric type `T` without any
tuples of scheduled times.

## Example ##
```
emp1Schedule = emptySchedule(Int)

isempty(emp1Schedule) # true

push!(emp1Schedule.day1, (9, 10), (13, 15))

isempty(emp1Schedule) # false

first(emp1Schedule) == (9, 10) # true
```
"""
emptySchedule(T) = Schedule(Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[])

"""
    schedules_isapprox(sched1, sched2)

Compare `Schedule`s `sched1` and `sched2` according to approximate equality of each scheduled time.
In particular, if the times represented in `sched1` and `sched2` are of different types (i.e. Int
and Float64) they cannot be identical, but they may be approximately equal.
"""
function schedules_isapprox(sched1::Schedule, sched2::Schedule)
    if length(sched1) != length(sched2)
        return false
    end
    sched1Flat = Iterators.flatten(_to_iter(sched1))
    sched2Flat = Iterators.flatten(_to_iter(sched2))
    for (v1, v2) in zip(sched1Flat, sched2Flat)
        if !isapprox(first(v1), first(v2))
            return false
        end
        if !isapprox(last(v1), last(v2))
            return false
        end
    end
    return true
end

"""
    s_min(s, bounds)

Calculate the intersection of each element in the Schedule `s` with the corresponding
overall bound in `bounds`.

## Example ##
```
emp1sched = Schedule(
    [(8, 10), (12, 15), (18, 20)], # Day 1 Availability
    [()], # Day 2 Availability
    [], # Day 3 Availability
    [(9, 17)], # Day 4 Availability
    [] # Day 5 Availability
    )

bounds = [
    (9, 17),
    (9, 17),
    (9, 17),
    (12, 17),
    (9, 17)
]

emp1Trimmed = s_min(emp1sched, bounds)

emp1Trimmed.day1 == [(9, 10), (12, 15)] # true
emp1Trimmed.day4 == [(12, 17)] # true
```
"""
function s_min(s::Schedule{T}, bounds::Vector{Tuple{T, T}}) where {T}
    Schedule(
    t_min(s.day1, bounds[1]),
    t_min(s.day2, bounds[2]),
    t_min(s.day3, bounds[3]),
    t_min(s.day4, bounds[4]),
    t_min(s.day5, bounds[5])
    )
end

###
# Employee and EmployeeList
###
export Employee, EmployeeList, avail

"""
    Employee(name, avail, specialty)

An `Employee` is an individual that can be scheduled. They have a `name`, availability `avail`,
and an integer `specialty`.
"""
struct Employee{T}
    name::String
    avail::Schedule{T}
    maxTime::Float64
    specialty::Int
end
function Employee(name::String, s::Schedule{T}, maxTime::Float64 = Inf64) where {T}
    Employee(name, s, maxTime, 0)
end
Schedule(e::Employee) = e.avail

function avail(e::Employee{T}) where {T}
    e.avail
end
function avail(e::Employee{T}, s::Symbol) where {T}
    getfield(avail(e), s)
end
function avail(e::Employee{T}, n::Int) where {T}
    avail(e, Symbol(:day, n))
end

"""
    EmployeeList

An EmployeeList is a list (Vector) of `Employees`.
"""
const EmployeeList{T} = Vector{Employee{T}}
