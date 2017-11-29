"""
_isvalid_block(t)

A Tuple `t` of numbers is only a valid time interval if it is written in increasing order.
"""
_isvalid_block(t::Tuple{T, T}) where {T <: Number} = last(t) > first(t)

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
function Base.next(sched::Schedule{T}, state::Int)::Tuple{Tuple{T,T}, Int} where {T}
    accum = 0
    for vec in _to_iter(sched)
        len = length(vec)
        if state <= accum + len
            return vec[state - accum], state + 1
        end
        accum += len
    end
end
Base.done(sched::Schedule, state::Int) = state > length(sched)
Base.eltype(::Type{Schedule{T}}) where {T} = Tuple{T, T}
function Base.getindex(sched::Schedule, i::Int)
    done(sched, i) && throw(BoundsError(sched, i))
    first(next(sched, i))
end
Base.endof(sched::Schedule) = length(sched)


"""
t_min(vec, overall)

Reduce the tuples in `vec` to their intersection with `overall`.
"""
function t_min(vec::Vector{Tuple{T, T}}, overall::Tuple{T, T}) where {T}
    omin, omax = overall
    filter(_isvalid_block, [(max(ft, omin), min(lt, omax)) for (ft, lt) in vec])
end