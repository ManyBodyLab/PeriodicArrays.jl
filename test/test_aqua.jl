using PeriodicArrays
using Aqua: Aqua
using Test

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(PeriodicArrays)
end
