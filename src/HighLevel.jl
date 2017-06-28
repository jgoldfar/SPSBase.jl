export Schedule, ScheduleWeights, Employee, EmployeeList

struct ScheduleWeights
    day1::Vector{Int}
    day2::Vector{Int}
    day3::Vector{Int}
    day4::Vector{Int}
    day5::Vector{Int}
end
struct Schedule{T<:Number}
    day1::Vector{Tuple{T, T}}
    day2::Vector{Tuple{T, T}}
    day3::Vector{Tuple{T, T}}
    day4::Vector{Tuple{T, T}}
    day5::Vector{Tuple{T, T}}
end
## Define some convenience functions for ScheduleWeights
_to_iter(weights::ScheduleWeights) = (getfield(weights, n) for n in fieldnames(weights))
_lengths(weights::ScheduleWeights) = map(length, _to_iter(weights))
Base.length(weights::ScheduleWeights) = sum(_lengths(weights))
## Define iteration over a Schedule for convenience.
_to_iter(sched::Schedule) = (getfield(sched, n) for n in fieldnames(sched))
_lengths(sched::Schedule) = map(length, _to_iter(sched))
Base.length(sched::Schedule) = sum(_lengths(sched))
Base.start(::Schedule) = 1
function Base.next{T}(sched::Schedule{T}, state::Int)
    accum = 0
    for n in fieldnames(sched)
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
Base.eltype{T}(::Type{Schedule{T}}) = Tuple{T, T}
function Base.getindex(sched::Schedule, i::Int)
    done(sched, i) && throw(BoundsError(sched, i))
    first(next(sched, i))
end
Base.endof(sched::Schedule) = length(sched)

isvalid(sched::Schedule, weights::ScheduleWeights) = length(weights) == length(sched)

function t_min{T}(vec::Vector{Tuple{T, T}}, overall::Tuple{T, T})
    isvalid(t::Tuple{T, T}) = first(t)<last(t)
    omin, omax = overall
    filter(isvalid, [(max(first(t), omin), min(last(t), omax)) for t in vec])
end
function s_min{T}(s::Schedule{T}, bounds::Vector{Tuple{T, T}})
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
