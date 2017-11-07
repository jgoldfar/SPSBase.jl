function _vec_len(s::Tuple{T, T}, increment::Real) where {T}
    f, l = s
    ceil(Int, (l - f)/increment)
end
function _length(sched::Schedule, increment::Real)
     sum(
     map(v -> _vec_len(v, increment),
     Iterators.flatten(_to_iter(sched)))
     )
 end
function to_vec(sched::Schedule, increment::Real = 1)
    BitVector(_length(sched, increment))
end
to_vec(e::Employee, increment::Real = 1) = to_vec(Schedule(e), increment)
to_vec(e::EmployeeList, increment::Real = 1) = BitVector(sum(_length(Schedule(t), increment) for t in e))

function _to_raw_sched(orig, vec, increment)
    vecindex = 0
    timeIncrement = Dates.Minute(60*increment)
    rawSched = emptySchedule(Float64)
    for day in fieldnames(typeof(orig))
        schedDay = getfield(orig, day)
        rawSchedDay = getfield(rawSched, day)
        for timeInterval in schedDay
            numTimes = _vec_len(timeInterval, increment)
            startTime = first(timeInterval)
            currStartTime = Float64(startTime)
            currentlyScheduled = false
            for time in 1:numTimes
                if vec[vecindex + time]
                    if !currentlyScheduled
                        currentlyScheduled = true
                        currStartTime = Float64(startTime + increment * (time - 1))
                    end
                else
                    if currentlyScheduled
                        push!(rawSchedDay, (currStartTime, Float64(startTime + increment * (time - 1))))
                        currentlyScheduled = false
                    end
                end
            end
            if currentlyScheduled
                push!(rawSchedDay, (currStartTime, Float64(startTime + increment * numTimes)))
            end
            vecindex += numTimes
        end
    end
    rawSched
end
# function expandInterval(tup1, tup2)
#     if first(tup2) == last(tup1)
#         return (first(tup1), last(tup2))
#     elseif last(tup2) == first(tup1)
#         return (first(tup2), last(tup1))
#     else
#         return tup1
#     end
# end
# function condense_day_sched(sched)
#     r1 = map(t->foldl(expandInterval, t, sched), sched)
#     r2 = map(t->foldl(expandInterval, t, r1), r1)
#     @show r2
#     r2
# end
# function _condense_sched(sched::Schedule)
#     for day in fieldnames(typeof(sched))
#         schedDay = getfield(sched, day)
        
#     end
#     return sched
# end
function to_sched(orig::Schedule, vec::AbstractVector{Bool}, increment::Real = 1)
    # rawSchedule = _to_raw_sched(orig, vec, increment)
    # return _condense_sched(rawSchedule)
    _to_raw_sched(orig, vec, increment)
end
function to_sched(orig::Employee, vec::AbstractVector{Bool}, increment::Real = 1)
    Employee(orig.name, to_sched(Schedule(orig), vec, increment), orig.specialty)
end
function to_sched(orig::EmployeeList, vec::AbstractVector{Bool}, increment::Real = 1)
    empsOut = Employee[]
    accum = 1
    for emp in orig
        len = length(to_vec(emp, increment))
        push!(empsOut, to_sched(emp, vec[accum:(accum + len)], increment))
    end
    empsOut
end