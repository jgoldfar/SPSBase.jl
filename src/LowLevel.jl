function _vec_len(s::Tuple{T, T}, increment::Real) where {T}
    f, l = s
    ceil(Int, (l - f)/increment)
end
"""
    _length(sched, increment)

Calculate the length of the vector generated by discretizing `sched::Schedule`
with time increment `increment`.
"""
function _length(sched::Schedule, increment::Real)
    sum(
        map(v -> _vec_len(v, increment),
        Iterators.flatten(_to_iter(sched)))
    )
 end

"""
    to_vec(sched, increment = 1)
    
Transform the "user-facing" `sched::Schedule` object to a `BitVector` for internal solvers.
The increment `increment` is interpreted as a fraction of an hour.
"""
function to_vec(sched::Schedule, increment::Real = 1)
    BitVector(_length(sched, increment))
end

"""
    to_vec(e, increment = 1)

Transforms the schedule component(s) of `e::Employee` or `e::EmployeeList`
to a `BitVector`.
"""
to_vec(e::Employee, increment::Real = 1) = to_vec(Schedule(e), increment)
to_vec(e::EmployeeList, increment::Real = 1) = BitVector(sum(_length(Schedule(t), increment) for t in e))

"""
    _to_raw_sched(orig, vec, increment)

Re-construct a schedule including only the times scheduled out of `orig::Schedule`
from the yes/no options in `vec::BitVector` constructed from orig using increment `increment`

`_to_raw_sched` makes an attempt to condense overlapping scheduled times to one longer
scheduled time.
"""
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

"""

"""
function to_sched(orig::Schedule, vec::AbstractVector{Bool}, increment::Real = 1)
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