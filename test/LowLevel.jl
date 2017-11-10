using SPS
@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@testset "LowLevel" begin
# Setup
emp1sched = Schedule(
[(8, 10), (12, 15), (18, 20)],
[(8, 10), (12, 15)],
[(9, -2), (10, 12)],
[(9, 17)],
[(9, 9), (13, 16)]
)
emp1 = Employee("Max", emp1sched, 0)

emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
emp2 = Employee("Limited", emp2sched, 0)

schedulingResolution = 1//2

@testset "Basic Vectorization Functionality" begin
    # Filling all of an employee's time makes to_vec and to_sched inverse functions when operating on Schedule objects
    emp1schedVec = SPS.to_vec(emp1sched, schedulingResolution)
    fill!(emp1schedVec, true)
    @test SPS.schedules_isapprox(SPS.to_sched(emp1sched, emp1schedVec, schedulingResolution), emp1sched)
    
    emp2schedVec = SPS.to_vec(emp2sched, schedulingResolution)
    fill!(emp2schedVec, true)
    @test SPS.schedules_isapprox(SPS.to_sched(emp2sched, emp2schedVec, schedulingResolution), emp2sched)
    
    for T in (Int, Float64, Rational{Int})
        shouldBeEmpty = SPS.emptySchedule(T)
        @test SPS._sps_vec_length(shouldBeEmpty, schedulingResolution) == 0
        @test SPS._sps_vec_length(shouldBeEmpty.day1, schedulingResolution) == 0
    end

    # Test that to_Vec works with an Employee object
    emp2Vec = SPS.to_vec(emp2, schedulingResolution)
    fill!(emp2Vec, true)
    @test emp2schedVec == emp2Vec
    # Same invariant as with the underlying schedule object
    @test SPS.schedules_isapprox(Schedule(SPS.to_sched(emp2, emp2Vec, schedulingResolution)), emp2sched)
    @test length(emp2Vec) == length(emp2schedVec)
    @test length(emp2Vec) == 4
    # Doubling the resolution doubles the number of elements
    @test length(SPS.to_vec(emp2sched, 1//4)) == 2*length(SPS.to_vec(emp2sched, 1//2))
end

@testset "Correctness of _to_raw_sched" begin
    testSched1 = Schedule(Dict(:day1 => [(9, 10)]))
    testSched1Resolution = 1//4
    testSched1Vec = SPS.to_vec(testSched1, testSched1Resolution)
    testSched1Vec[1] = true
    testSched1Vec[2] = true
    rawSched1 = SPS._to_raw_sched(testSched1, testSched1Vec, testSched1Resolution)
    @test length(rawSched1.day1) == 1 && first(rawSched1) == (9.0, 9.5)

    testSched1Vec[2] = false
    testSched1Vec[3] = true
    rawSched1 = SPS._to_raw_sched(testSched1, testSched1Vec, testSched1Resolution)
    @test length(rawSched1.day1) == 2 && first(rawSched1) == (9.0, 9.25)

    testSched2 = Schedule(Dict(:day1 => [(9, 11)], :day2 => [(13, 15), (15, 16)]))
    testSched2Resolution = 1//2
    testSched2Vec = SPS.to_vec(testSched2, testSched2Resolution)
    testSched2Vec[1] = true
    testSched2Vec[2] = true
    testSched2Vec[7] = true
    testSched2Vec[8] = true
    testSched2Vec[9] = true
    rawSched2 = SPS._to_raw_sched(testSched2, testSched2Vec, testSched2Resolution)
    @test_broken length(rawSched2) == 2
    @test length(rawSched2.day1) == 1 && first(rawSched2.day1) == (9.0, 10.0)
    @test_broken length(rawSched2.day2) == 1 && first(rawSched2.day2) == (14.0, 15.5)
end

@testset "BitSchedule" begin
    bsTestSched = Schedule(
        [(8, 10)],
        [(12, 15)],
        [(10, 12)],
        [(9, 9)],
        [(9, 9)]
        )
    bs = SPS.BitSchedule(bsTestSched, schedulingResolution)
    nvExpected = SPS._sps_vec_length(bsTestSched, schedulingResolution)
    @test length(bs.vec) == length(bs.times) == nvExpected
    @test isapprox(first(bs.times), first(first(bs.sched.day1)) + 100)
    @test !any(bs.times .<= 100.0)
    @test isapprox(bs.increment, schedulingResolution)
    @testset "to_adjacency_mat" begin
        bsAdjacencyMatrix = SPS.to_adjacency_mat(bs)
        @test size(bsAdjacencyMatrix) == (nvExpected, nvExpected)
        @test all(transpose(bsAdjacencyMatrix) .== bsAdjacencyMatrix)
        # 8 is adjacent to 8+1//2 and 8 + 1//2 is adjacent to 8 + 1//2 + 1//2
        @test bsAdjacencyMatrix[1, 2] && bsAdjacencyMatrix[2, 3]
        # 8 is not adjacent to 9, and 10 is not adjacent to 12 of next day
        @test !bsAdjacencyMatrix[1, 3] && !bsAdjacencyMatrix[4, 5]
    end
end

@testset "EmployeeList" begin
    # An EmployeeList is just a list of employees...
    nEmployees = 2
    emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
    emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), nEmployees + 1)
    employees = push!(
        [Employee("Limited $i", emp2sched, i) for i in 1:nEmployees],
        emp3
    )
    
    # Test vectorizationof a list of employees
    employeesVec = SPS.to_vec(employees, schedulingResolution)
    fill!(employeesVec, true)

    # The length of the vectorized employeelist should be the sum of the lengths of its member vectors
    length_emp2Vec = length(SPS.to_vec(emp2, schedulingResolution))
    length_emp2Components = nEmployees*length_emp2Vec
    length_employeesVec = length(employeesVec)
    @test length_employeesVec == length_emp2Components + length(SPS.to_vec(emp3, schedulingResolution))

    # to_vec and to_sched are nearly inverse functions
    employeeSchedules = SPS.to_sched(employees, employeesVec, schedulingResolution)
    for (i, v) in enumerate(employees)
        @test SPS.schedules_isapprox(Schedule(employeeSchedules[i]), Schedule(v))
        @test employeeSchedules[i].name == v.name && employeeSchedules[i].specialty == v.specialty
    end

    @testset "BitScheduleList" begin
        bsl = SPS.BitScheduleList(employees, schedulingResolution)
        @test !any(bsl.times .<= 1.0)
        @test isapprox(bsl.increment, schedulingResolution)
        
        @testset "to_overlap_mat" begin
            bslOverlapMatrix = SPS.to_overlap_mat(bsl)
            @test all(diag(bslOverlapMatrix))
            @test !any(diag(bslOverlapMatrix, 1))
            correctRepeatingStructure = true
            for i in 1:(length_emp2Components - length_emp2Vec)
                correctRepeatingStructure = correctRepeatingStructure && 
                bslOverlapMatrix[i, i+length_emp2Vec]
            end
            @test correctRepeatingStructure

            correctOffdiagStructure = true
            for i in (length_emp2Components+1):length_employeesVec
                correctOffdiagStructure = correctOffdiagStructure && !any(bslOverlapMatrix[i, i+1:end])
            end
            @test correctOffdiagStructure
            
            correctStructure = true
            for i in 1:length_employeesVec
                for j in 1:length_employeesVec
                    correctStructure = correctStructure && (bslOverlapMatrix[j, i] == (bsl.times[j] == bsl.times[i]))
                end
            end
            @test correctStructure

            @test all(SPS.to_overlap_mat([1.0, 1.0, 1.0]))

            bslOverlapMatrix2 = SPS.to_overlap_mat([1.0, 2.0, 1.5, 1.0])
            @test bslOverlapMatrix2 == [true false false true;
                                        false true false false;
                                        false false true false;
                                        true false false true]

            bslOverlapMatrix3 = SPS.to_overlap_mat([1.1, 1.01, 1.1, 1.1])
            @test bslOverlapMatrix3 == [true false true true;
                                        false true false false;
                                        true false true true;
                                        true false true true]
        end
    end
end
end # testset