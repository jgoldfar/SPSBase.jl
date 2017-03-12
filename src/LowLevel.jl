# immutable ScheduleVector
#     day1::BitVector
#     day2::BitVector
#     day3::BitVector
#     day4::BitVector
#     day5::BitVector
# end
function _to_vec_len{T}(s::Tuple{T, T}, increment::Real)
    f, l = s
    ceil(Int, (l - f)/increment)
end

function to_vec(sched::Schedule, increment::Real)
    veclen =
    sum(map(v -> _to_vec_len(v, increment), sched.day1))+
    sum(map(v -> _to_vec_len(v, increment), sched.day2))+
    sum(map(v -> _to_vec_len(v, increment), sched.day3))+
    sum(map(v -> _to_vec_len(v, increment), sched.day4))+
    sum(map(v -> _to_vec_len(v, increment), sched.day5))
    BitVector(veclen)
end

function to_sched(orig::Schedule, vec::Vector{Bool}, increment::Real)

end
