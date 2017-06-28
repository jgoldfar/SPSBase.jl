function _vec_len{T}(s::Tuple{T, T}, increment::Real)
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

function to_sched(orig::Schedule, vec::AbstractVector{Bool}, increment::Real = 1)

end
