export Schedule, Employee, ScheduleWeights

immutable ScheduleWeights
    day1::Vector{Int}
    day2::Vector{Int}
    day3::Vector{Int}
    day4::Vector{Int}
    day5::Vector{Int}
end
immutable Schedule{T}
    day1::Vector{Tuple{T, T}}
    day2::Vector{Tuple{T, T}}
    day3::Vector{Tuple{T, T}}
    day4::Vector{Tuple{T, T}}
    day5::Vector{Tuple{T, T}}
end
immutable Employee
    name::String
    avail::Schedule
    specialty::Int
end
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
