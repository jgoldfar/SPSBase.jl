for T in (Int, Float64)
    precompile(t_min, (Vector{Tuple{T, T}}, Tuple{T, T}))
    precompile(s_min, (Schedule{T}, Vector{Tuple{T, T}}))
    for T2 in (Int, Float64, Rational{Int})
        precompile(schedules_isapprox, (Schedule{T}, Schedule{T2}))
        
        precompile(_sps_vec_length, (Vector{Tuple{T, T}}, T2))
        precompile(_sps_vec_length, (Schedule{T}, T2))
        precompile(to_vec, (Schedule{T}, T2))
        precompile(_to_raw_sched, (Schedule{T}, BitVector, T2))
        precompile(to_sched, (Schedule{T}, BitVector, T2))
    end

    precompile(_create_times_vec!, (Vector{Float64}, Schedule{T}, Int, T))
    precompile(to_adjacency_mat, (BitVector, Vector{Float64}, T))
    precompile(to_overlap_mat, (Vector{Float64},))
    precompile(generateFunctional, (EmployeeList{T},))
end