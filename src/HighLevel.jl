export Schedule, Employee, EmployeeList

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

_isvalid_block(t::Tuple{T, T}) where {T <: Number} = last(t) > first(t)

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

emptySchedule(T) = Schedule(Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[], Tuple{T,T}[])

## Define iteration over a Schedule for convenience.
_to_iter(sched::Schedule) = (getfield(sched, n) for n in fieldnames(typeof(sched)))
_lengths(sched::Schedule) = map(length, _to_iter(sched))
Base.length(sched::Schedule) = sum(_lengths(sched))
Base.start(::Schedule) = 1
function Base.next(sched::Schedule{T}, state::Int) where {T}
    accum = 0
    for n in fieldnames(typeof(sched))
        vec = getfield(sched, n)
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

function t_min(vec::Vector{Tuple{T, T}}, overall::Tuple{T, T}) where {T}
    isvalid(t::Tuple{T, T}) = first(t)<last(t)
    omin, omax = overall
    filter(isvalid, [(max(first(t), omin), min(last(t), omax)) for t in vec])
end
function s_min(s::Schedule{T}, bounds::Vector{Tuple{T, T}}) where {T}
    Schedule(
    t_min(s.day1, bounds[1]),
    t_min(s.day2, bounds[2]),
    t_min(s.day3, bounds[3]),
    t_min(s.day4, bounds[4]),
    t_min(s.day5, bounds[5])
    )
end

struct Employee
    name::String
    avail::Schedule
    specialty::Int
end
Base.convert(::Type{Schedule}, e::Employee) = e.avail

const EmployeeList = Vector{Employee}
