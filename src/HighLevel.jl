export Schedule
"""
    _isvalid_block(t)

A Tuple `t` of numbers is only a valid time interval if it is written in increasing order.
"""
_isvalid_block(t::Tuple{T, T}) where {T <: Number} = last(t) > first(t)

"""
    Schedule(day1, day2, day3, day4, day5)

A schedule is a relatively easy-to-write form of either an availability schedule
or collection of times scheduled; each `day` is a Vector of Tuples of Numbers 
representing the start and end times.

`Schedule`s admit an iterator interface (that is, they can be indexed into, have a
specified length, etc.)
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
    emptySchedule(T)

Construct a `Schedule` object with elements of numeric type `T` without any
tuples of scheduled times.
"""
emptySchedule(T) = Schedule(Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[])

## Define iteration over a Schedule for convenience.
"""
    _to_iter(sched)

Define an iterator over the fields of `sched::Schedule` for convenience.
"""
_to_iter(sched::Schedule) = (getfield(sched, n) for n in fieldnames(typeof(sched)))
"""
    _lengths(sched)

Return an iterator over the lengths of each field in `sched::Schedule`.
"""
_lengths(sched::Schedule) = map(length, _to_iter(sched))
Base.length(sched::Schedule) = sum(_lengths(sched))
Base.start(::Schedule) = 1
function Base.next(sched::Schedule{T}, state::Int) where {T}
    accum = 0
    for vec in _to_iter(sched)
        len = length(vec)
        if state <= accum + len
            return vec[state - accum], state + 1
        end
        accum += len
    end
    return (zero(T), zero(T)), state + 1
end
Base.done(sched::Schedule, state::Int) = state > length(sched)
Base.eltype(::Type{Schedule{T}}) where {T} = Tuple{T, T}
function Base.getindex(sched::Schedule, i::Int)
    done(sched, i) && throw(BoundsError(sched, i))
    first(next(sched, i))
end
Base.endof(sched::Schedule) = length(sched)

"""
    schedules_isapprox(sched1, sched2)

Compare `Schedule`s `sched1` and `sched2` according to approximate equality of each scheduled time.
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
    t_min(vec, overall)

Reduce the tuples in `vec` to their intersection with `overall`.
"""
function t_min(vec::Vector{Tuple{T, T}}, overall::Tuple{T, T}) where {T}
    omin, omax = overall
    filter(_isvalid_block, [(max(first(t), omin), min(last(t), omax)) for t in vec])
end

"""
    s_min(s, bounds)

Calculate the intersection of each element in the Schedule `s` with the corresponding
overall bound in `bounds`.
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
# ScheduleWeights
###

# export ScheduleWeights
# struct ScheduleWeights
#     day1::Vector{Int}
#     day2::Vector{Int}
#     day3::Vector{Int}
#     day4::Vector{Int}
#     day5::Vector{Int}
# end
## Define some convenience functions for ScheduleWeights
# _to_iter(weights::ScheduleWeights) = (getfield(weights, n) for n in fieldnames(typeof(weights)))
# _lengths(weights::ScheduleWeights) = map(length, _to_iter(weights))
# Base.length(weights::ScheduleWeights) = sum(_lengths(weights))

# isvalid(sched::Schedule, weights::ScheduleWeights) = length(weights) == length(sched)


###
# Employee and EmployeeList
###
export Employee, EmployeeList

"""
    Employee(name, avail, specialty)

An `Employee` is an individual that can be scheduled. They have a `name`, availability `avail`,
and an integer `specialty`.
"""
struct Employee
    name::String
    avail::Schedule
    specialty::Int
end
Base.convert(::Type{Schedule}, e::Employee) = e.avail

"""
    EmployeeList

An EmployeeList is a list (Vector) of `Employees`
"""
const EmployeeList = Vector{Employee}
