@static if VERSION >= v"0.7-"
	using LinearAlgebra: Symmetric, Tridiagonal
else
	using Compat: undef, reduce
end

function _vec_len(s::Tuple{T, T}, increment::Real) where {T}
    f, l = s
    ceil(Int, (l - f)/increment)
end

"""
    _sps_vec_length(day, increment)

Calculate the length of the vector generated by discretizing `day::Vector{Tuple{T, T}}`
with time increment `increment`.
"""
function _sps_vec_length(day::Vector{Tuple{T, T}}, increment::Real) where {T}
    reduce(+, _vec_len(v, increment) for v in day; init = 0)
end

"""
    _sps_vec_length(sched, increment)

Calculate the length of the vector generated by discretizing `sched::Schedule`
with time increment `increment`.
"""
function _sps_vec_length(sched::Schedule, increment::Real)
    reduce(+, _sps_vec_length(v, increment) for v in _to_iter(sched); init = 0)
end

"""
_sps_vec_length(el, increment)

Calculate the length of the vector generated by discretizing `el::EmployeeList`
with time increment `increment`.
"""
function _sps_vec_length(el::EmployeeList, increment::Real)
    sum(_sps_vec_length(Schedule(t), increment) for t in el)
end

"""
    to_vec(sched, increment = 1)
    
Transform the "user-facing" `sched::Schedule` object to a `BitVector` for internal solvers.
The increment `increment` is interpreted as a fraction of an hour.
"""
function to_vec(sched::Schedule, increment::Real = 1)
    BitVector(undef, _sps_vec_length(sched, increment))
end

"""
    to_vec(e, increment = 1)

Transforms the schedule component(s) of `e::Employee` or `e::EmployeeList`
to a `BitVector`.
"""
to_vec(e::Employee, increment::Real = 1) = to_vec(Schedule(e), increment)
to_vec(e::EmployeeList, increment::Real = 1) = BitVector(undef, _sps_vec_length(e, increment))

###
# Helpers for conversion between high-level UI and these lower-level constructs
###
@static if VERSION >= v"0.7-"
    import Dates
else
    import Base.Dates
end
"""
    _to_raw_sched(orig, vec, increment)

Re-construct a schedule including only the times scheduled out of `orig::Schedule`
from the yes/no options in `vec::BitVector` constructed from orig using increment `increment`.

`_to_raw_sched` makes an attempt to condense overlapping scheduled times to one longer
scheduled time.
"""
function _to_raw_sched(orig, vec, increment)
    #TODO: Separate basic translation from vector to schedule from schedule consolidation.
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
to_sched(bs)

Re-construct a schedule including only the times scheduled out of `bs::BitSchedule`.

`to_sched` also operates on `orig::Employee`, `orig::EmployeeList`, `orig::BitSchedule`,
and `orig::BitScheduleList`.

The current implementation is entirely contained in _to_raw_sched, but more separation into
separate functionality is planned.
"""
function to_sched(orig::Schedule, vec::AbstractVector{Bool}, increment::Real = 1)::Schedule{Float64}
    _to_raw_sched(orig, vec, increment)
end
function to_sched(orig::Employee, vec::AbstractVector{Bool}, increment::Real = 1)::Employee{Float64}
    Employee(orig.name, to_sched(Schedule(orig), vec, increment), orig.maxTime, orig.specialty)
end
function to_sched(orig::EmployeeList, vec::AbstractVector{Bool}, increment::Real = 1)::EmployeeList{Float64}
    empsOut = Employee[]
    accum = 1
    for emp in orig
        len = length(to_vec(emp, increment))
        push!(empsOut, to_sched(emp, vec[accum:(accum + len)], increment))
    end
    empsOut
end

###
# Types below encapsulate low-level information about the control vector
###
function _create_times_vec!(times::Vector{Float64}, s::Schedule{T}, timesInd::Int = 1, increment::Real = 1) where {T<:Number}
    floatIncrement = Float64(increment)
    for (i, day) in enumerate(_to_iter(s))
        for block in day
            blockStart = first(block)
            nBlockValues = _vec_len(block, increment)
            for j in 0:(nBlockValues - 1)
                times[timesInd + j] = (blockStart + j * floatIncrement) + 100i
            end
            timesInd += nBlockValues
        end
    end
    timesInd
end

export BitSchedule, BitScheduleList

"""
    BitSchedule(sched, vec, times, increment)

Encapsulates the time information corresponding to each element of `vec::BitVector`
in the `times::Vector{Float64}` vector; each time in `times` is encoded in the form
`ijj.mmm` where `i` is the day number, `jj` is the hour number, and `mmm` is the
fraction of an hour corresponding to the element in `vec`. The `sched::Schedule` and
`increment` are retained to avoid recomputing parameters.
"""
struct BitSchedule{T<:Number}
    sched::Schedule{T}
    vec::BitVector
    times::Vector{Float64}
    increment::Float64
    function BitSchedule(s::Schedule{T}, increment::Real = 1) where {T<:Number}
        vec = to_vec(s, increment)
        times = Vector{Float64}(undef, length(vec))
        _create_times_vec!(times, s, 1, increment)
        new{T}(s, vec, times, Float64(increment))
    end
end

struct BitScheduleList{T<:Number}
    employees::EmployeeList{T}
    vec::BitVector
    times::Vector{Float64}
    increment::Float64
    function BitScheduleList(empList::EmployeeList{T}, increment::Real = 1) where {T<:Number}
        vec = to_vec(empList, increment)
        times = Vector{Float64}(undef, length(vec))
        accum = 1
        for e in empList
            accum = _create_times_vec!(times, e.avail, accum, increment)
        end
        new{T}(empList, vec, times, Float64(increment))
    end
end

"""
    `to_sched(orig)`

operates on `orig::BitSchedule` and `orig::BitScheduleList`.
"""
to_sched(orig::BitSchedule) = to_sched(orig.sched, orig.vec, orig.increment)
to_sched(orig::BitScheduleList) = to_sched(orig.employees, orig.vec, orig.increment)
###
# Helpers for functional generation
###

getEmployeeIndices(bsl::BitScheduleList) = getEmployeeIndices(bsl.employees, bsl.increment)
function getEmployeeIndices(empList::EmployeeList, increment::Real)
    empInds = Vector{typeof(1:2)}(undef, length(empList))
    ind = 1
    for (i, emp) in enumerate(empList)
        ne = _sps_vec_length(emp.avail, increment)
        empInds[i] = ind:(ind + ne - 1)
        ind += ne
    end
    empInds
end

"""
to_adjacency_mat(sched, vec, increment)

For each entry in `vec::BitVector` generated from `sched::Schedule`, determine which other entries
in `vec` are adjacent in real time, assuming they were generated with increment `increment`.

Returns a AbstractMatrix{Bool} containing adjacency information.
"""
function to_adjacency_mat(times::Vector{Float64}, increment::Real)
    nv = length(times)
    bmo = Tridiagonal(BitVector(undef, nv-1), BitVector(undef, nv), BitVector(undef, nv-1))
    floatIncrement = Float64(increment)
    bmo[1, 2] = isapprox(times[2], times[1] + floatIncrement)
    for i in 2:(nv-1)
        bmo[i, i - 1] = isapprox(times[i], times[i - 1] + floatIncrement)
        bmo[i, i + 1] = isapprox(times[i], times[i + 1] - floatIncrement)
    end
    bmo[nv, nv - 1] = isapprox(times[nv], times[nv - 1] + floatIncrement)
    bmo
end

"""
    to_adjacency_mat(bs)

Evaluate `to_adjacency_mat` on the `vec` and `times` components of `bs::BitSchedule`
"""
to_adjacency_mat(bs::BitSchedule) = to_adjacency_mat(bs.times, bs.increment)

function _to_adjacency_mat(bsl::BitScheduleList)
    timesInd = 1
    ne1 = _sps_vec_length(bsl.employees[1].avail, bsl.increment)
    adjMat1 = to_adjacency_mat(bsl.times[timesInd:(timesInd + ne1 - 1)], bsl.increment)
    

    #NOTE: Explicit assumption about structure of bsl.employees.
    nEmployees = length(bsl.employees)
    adjMats = Vector{typeof(adjMat1)}(undef, nEmployees)
    adjMats[1] = adjMat1
    timesInd += ne1
    
    for i in 2:nEmployees
        e = bsl.employees[i]
        ne = _sps_vec_length(e.avail, bsl.increment)
        adjMats[i] = to_adjacency_mat(bsl.times[timesInd:(timesInd + ne - 1)], bsl.increment)
        timesInd += ne
    end
    adjMats
end
function to_adjacency_mat(bsl::BitScheduleList)
    nv = length(bsl.vec)
    adjMats = _to_adjacency_mat(bsl)
    adjMat = falses(nv, nv)
    matPtr = 1
    for mat in adjMats
        nAdj = size(mat, 1)
        adjMat[matPtr:(matPtr+nAdj-1),matPtr:(matPtr+nAdj-1)] = Matrix(mat)
        matPtr += nAdj
    end
    adjMat
end

"""
to_overlap_mat(empList, times)

For each entry in `times::Vector{Float64}`, determine which other entries occur at the same time.

Returns an AbstractMatrix{Bool} containing overlap information. That is, if the element in
position [i, j] is true, then times[i] == times[j].
"""
function to_overlap_mat(times::Vector{Float64})
    nv = length(times)
    bmo = falses(nv, nv)
    for (i, t) in enumerate(times)
        sameInd = times .== t
        bmo[i, sameInd] .= true
    end
    
    Symmetric(bmo)
end
to_overlap_mat(bsl::BitScheduleList) = to_overlap_mat(bsl.times)