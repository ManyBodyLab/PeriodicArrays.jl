using PeriodicArrays
using Test
using OffsetArrays

@testset "index style" begin
    @test IndexStyle(PeriodicArray) == IndexCartesian()
    @test IndexStyle(PeriodicVector) == IndexLinear()
end

@testset "construction" begin
    @testset "construction ($T)" for T in (Float64, Int)
        data = rand(T, 10)
        arrays = [
            PeriodicVector(data), PeriodicVector{T}(data),
            PeriodicArray(data), PeriodicArray{T}(data), PeriodicArray{T, 1}(data),
        ]
        @test all(a == first(arrays) for a in arrays)
        @test all(a isa PeriodicVector{T, Vector{T}} for a in arrays)
    end

    @testset "matrix construction" begin
        data = zeros(Float64, 2, 2)
        ref = PeriodicMatrix(data)
        @test PeriodicArray{Float64, 2}(data) == ref
        @test PeriodicMatrix{Float64}(data) == ref
        @test PeriodicMatrix{Float64, Array{Float64, 2}}(data) == ref
        @test PeriodicMatrix{Float64, Matrix{Float64}}(data) == ref
    end
end

@testset "type stability" begin
    @testset "type stability $(n)d" for n in 1:10
        a = PeriodicArray(fill(1, ntuple(_ -> 1, n)))

        @test @inferred(a[1]) isa Int64
        @test @inferred(a[[1]]) isa PeriodicVector{Int64}
        @test @inferred(a[[1]']) isa PeriodicArray{Int64, 2}
        @test @inferred(axes(a)) isa Tuple{Vararg{AbstractUnitRange}}
        @test @inferred(similar(a)) isa typeof(a)
        @test @inferred(similar(a, Float64, Int8.(size(a)))) isa PeriodicArray{Float64}
        @test @inferred(a[a]) isa typeof(a)
    end
end

@testset "display" begin
    @testset "display $(n)d" for n in 1:3
        data = rand(Int64, ntuple(_ -> 3, n))
        v1 = PeriodicArray(data)
        io = IOBuffer()
        io_compare = IOBuffer()

        print(io, v1)
        print(io_compare, data)
        @test String(take!(io)) == String(take!(io_compare))

        print(io, summary(v1))
        print(io_compare, summary(data))

        text = String(take!(io_compare))
        text = replace(text, " Vector" => " PeriodicVector")
        text = replace(text, " Matrix" => " PeriodicArray")
        text = replace(text, " Array" => (n == 1 ? " PeriodicVector" : " PeriodicArray"))
        text = replace(text, r"{.+}" => "(::$(string(typeof(data))))")
        @test String(take!(io)) == text
    end
end

@testset "vector" begin
    data = rand(Int64, 5)
    v1 = PeriodicVector(data)

    @test size(v1, 1) == 5
    @test parent(v1) == data
    @test typeof(v1) == PeriodicVector{Int64, Vector{Int64}, typeof(PeriodicArrays.identity_map), typeof(PeriodicArrays.identity_map)}
    @test isa(v1, PeriodicVector)
    @test isa(v1, AbstractVector{Int})
    @test !isa(v1, AbstractVector{String})
    @test v1[2] == v1[2 + length(v1)]

    @test IndexStyle(v1) == IndexStyle(typeof(v1)) == IndexLinear()
    @test v1[0] == data[end]
    @test v1[-4:10] == [data; data; data]
    @test v1[-3:1][-1] == data[end]
    @test v1[[true, false, true, false, true]] == v1[[1, 3, 0]]
    @test all(e in data for e in v1)
    @test all(e in v1 for e in data)

    v1copy = copy(v1)
    v1_2 = v1[2]
    v1[2] = 0
    v1[3] = 0
    @test v1[2] == v1[3] == 0
    @test v1copy[2] == v1_2
    @test v1copy[7] == v1_2
    @test_throws MethodError v1[2] = "Hello"

    v2 = PeriodicVector("abcde", 5)

    @test prod(v2) == "abcde"^5

    @testset "empty/empty!" begin
        v1 = PeriodicVector([1, 2, 3])
        @test empty(v1) isa PeriodicVector{Int64}
        @test empty(v1, Float64) isa PeriodicVector{Float64}
        v1 == PeriodicVector([])
        # `isempty` can be used to implement `size` method.
        @test isempty(empty(v1))

        v2 = PeriodicVector("abcde", 5)
        @test empty!(v2) isa PeriodicVector{String}
        @test isempty(v2)
    end

    @testset "resize!" begin
        @test_throws ArgumentError("new length must be ≥ 0") resize!(PeriodicVector([]), -2)
        v = PeriodicVector([1, 2, 3, 4, 5, 6, 7])
        resize!(v, 3)
        @test length(v) == 3

        # ensure defining `resize!` induces `push!` and `append!` methods
        @testset "push!" begin
            v = PeriodicVector([1, 2, 3])
            push!(v, 42)
            @test v == PeriodicVector([1, 2, 3, 42])
            push!(v, -9, -99, -999)
            @test v == PeriodicVector([1, 2, 3, 42, -9, -99, -999])
        end

        @testset "append!" begin
            v1 = PeriodicVector([1, 2, 3])
            append!(v1, [-9, -99, -999])
            @test v1 == PeriodicVector([1, 2, 3, -9, -99, -999])

            v2 = PeriodicVector([1, 2, 3])
            append!(v2, PeriodicVector([-1, -2]))
            @test v2 == PeriodicVector([1, 2, 3, -1, -2])

            v3 = PeriodicVector([1, 2, 3])
            append!(v3, [4, 5], [6])
            @test v3 == PeriodicVector([1, 2, 3, 4, 5, 6])

            v4 = PeriodicVector([1, 2, 3])
            o4 = OffsetVector([-1, -2, -3], -2:0)
            append!(v4, o4)
            @test v4 == PeriodicVector([1, 2, 3, -1, -2, -3])

            v5 = PeriodicVector([1, 2, 3])
            o5 = OffsetVector([-1, -2, -3], -2:0)
            append!(v5, o5, -4)
            @test v5 == PeriodicVector([1, 2, 3, -1, -2, -3, -4])
        end
    end

    @testset "pop!" begin
        v1 = PeriodicVector([1, 2, 3, 42])
        pop!(v1) == 42
        @test v1 == PeriodicVector([1, 2, 3])

        v2 = PeriodicVector([1])
        pop!(v2) == 1
        @test v2 == PeriodicVector([])
        @test isempty(v2)
        @test_throws ArgumentError("array must be non-empty") pop!(v2)
    end

    @testset "sizehint!" begin
        v = PeriodicVector([1, 2, 3, 4, 5, 6, 7])
        resize!(v, 1)
        sizehint!(v, 1)
        @test length(v) == 1
    end

    @testset "deleteat!" begin
        @test deleteat!(PeriodicVector([1, 2, 3]), 2) == PeriodicVector([1, 3])
        @test deleteat!(PeriodicVector([1, 2, 3]), 5) == PeriodicVector([1, 3])
        @test deleteat!(PeriodicVector([1, 2, 3]), 4) == PeriodicVector([2, 3])
        @test deleteat!(PeriodicVector([1, 2, 3]), 0) == PeriodicVector([1, 2])
        @test deleteat!(PeriodicVector([1, 2, 3, 4]), 1:5:10) == PeriodicVector([3, 4])
        @test deleteat!(PeriodicVector([1, 2, 3, 4]), [1, 5]) == PeriodicVector([2, 3, 4])
        @test deleteat!(PeriodicVector([1, 2, 3, 4]), (1, 5)) == PeriodicVector([2, 3, 4])
        @test deleteat!(PeriodicVector([1, 2, 3, 4]), (1, 6)) == PeriodicVector([3, 4])
        @test deleteat!(PeriodicVector([1, 2, 3, 4]), (1, 3, 5)) == PeriodicVector([2, 4])
        @test deleteat!(PeriodicVector([1, 2, 3, 4]), (1, 5, 7)) == PeriodicVector([2, 4])
    end

    @testset "insert!" begin
        @test insert!(PeriodicVector([1, 2, 3]), 2, 4) == PeriodicVector([1, 4, 2, 3])
        @test insert!(PeriodicVector([1, 2, 3]), 5, 4) == PeriodicVector([1, 4, 2, 3])
        @test insert!(PeriodicVector([1, 2, 3]), 4, 4) == PeriodicVector([4, 1, 2, 3])
        @test insert!(PeriodicVector([1, 2, 3]), 0, 4) == PeriodicVector([1, 2, 4, 3])
    end

    @testset "doubly periodic" begin
        a = PeriodicVector([1, 2, 3, 4, 5])
        b = PeriodicVector(a)

        @test all(a[i] == b[i] for i in -50:50)
    end

    @testset "type stability" begin
        v3 = @inferred(fmap(x -> x + 1, PeriodicArray([1, 2, 3, 4])))
        @test v3 isa PeriodicVector{Int64}
        @test v3 == PeriodicArray([2, 3, 4, 5])
        @test similar(v3, Base.OneTo(4)) isa typeof(v3)

        v4 = @inferred(PeriodicArray([1, 2, 3, 4]) .+ 1)
        @test v4 isa PeriodicVector{Int64}
        @test v4 == PeriodicArray([2, 3, 4, 5])

        v5 = v4 .> 3
        @test v5 isa PeriodicVector{Bool, Vector{Bool}}
        @test v5 == PeriodicArray([0, 0, 1, 1])

        # scalar-first broadcast (previously: FieldError on `fmap`)
        v6 = @inferred(1 .+ PeriodicArray([1, 2, 3, 4]))
        @test v6 isa PeriodicVector{Int64}
        @test v6 == PeriodicArray([2, 3, 4, 5])

        # two PeriodicArrays with different element types (previously: fell back to plain Array)
        v7 = @inferred(PeriodicArray([1, 2, 3]) .+ PeriodicArray([1.0, 2.0, 3.0]))
        @test v7 isa PeriodicVector{Float64}

        # PeriodicArray broadcast with plain array
        v8 = @inferred(PeriodicArray([1, 2, 3]) .+ [10, 20, 30])
        @test v8 isa PeriodicVector{Int64}
    end
end

@testset "matrix" begin
    b_arr = [2 4 6 8; 10 12 14 16; 18 20 22 24]
    a1 = PeriodicMatrix(b_arr)
    @test size(a1) == (3, 4)
    @test parent(a1) == b_arr

    @test a1[2, 3] == 14
    @test a1[2, Int32(3)] == 14
    a1[2, 3] = 17
    @test a1[2, 3] == 17
    @test a1[-1, 7] == 17
    @test a1[CartesianIndex(-1, 7)] == 17
    @test a1[-1:5, 4:10][1, 4] == 17
    @test a1[:, -1:-1][2, 1] == 17
    a1[CartesianIndex(-2, 7)] = 99
    @test a1[1, 3] == 99

    a1[18] = 9
    @test a1[18] == a1[-6] == a1[6] == a1[3, 2] == a1[0, 6] == b_arr[3, 2] == b_arr[6] == 9

    @test IndexStyle(a1) == IndexStyle(typeof(a1)) == IndexCartesian()
    @test a1[3] == a1[3, 1]
    @test a1[Int32(4)] == a1[1, 2]
    @test a1[-1] == a1[length(a1) - 1]

    @test a1[2, 3, 1] == 17 # trailing index
    @test a1[2, 3, 99] == 17
    @test a1[2, 3, :] == [17]

    @test !isa(a1, PeriodicVector)
    @test !isa(a1, AbstractVector)
    @test isa(a1, AbstractMatrix)
    @test isa(a1, AbstractArray)

    @test size(reshape(a1, (2, 2, 3))) == (2, 2, 3)

    a2 = PeriodicMatrix(4, (2, 3))
    @test isa(a2, PeriodicMatrix{Int})
    @test isa(a2, PeriodicArray{Int, 2})

    a3 = @inferred(a2 .+ 1)
    @test a3 isa PeriodicMatrix{Int64}
    @test a3 isa PeriodicArray{Int64, 2}
    @test a3 == PeriodicArray(5, (2, 3))

    @testset "doubly periodic" begin
        a = PeriodicMatrix(b_arr)
        da = PeriodicMatrix(a)

        @test da isa PeriodicMatrix
        @test all(a[i, j] == da[i, j] for i in -8:8, j in -8:8)
        @test all(a[i] == da[i] for i in -50:50)
    end
end

@testset "3-array" begin
    t3 = collect(reshape('a':'x', 2, 3, 4))
    c3 = PeriodicArray(t3)

    @test parent(c3) == t3

    @test c3[1, 3, 3] == c3[3, 3, 3] == c3[3, 3, 7] == c3[3, 3, 7, 1]

    c3[3, 3, 7] = 'Z'
    @test t3[1, 3, 3] == 'Z'

    @test c3[3, CartesianIndex(3, 7)] == 'Z'
    c3[Int32(3), CartesianIndex(3, 7)] = 'ζ'
    @test t3[1, 3, 3] == 'ζ'

    c3[34] = 'J'
    @test c3[34] == c3[-38] == c3[10] == c3[2, 2, 2] == c3[4, 5, 6] == t3[2, 2, 2] == t3[10] == 'J'

    @test vec(c3[:, [CartesianIndex()], 1, 5]) == vec(t3[:, 1, 1])

    @test IndexStyle(c3) == IndexStyle(typeof(c3)) == IndexCartesian()
    @test c3[-1] == t3[length(t3) - 1]

    @test_throws BoundsError c3[2, 3] # too few indices
    @test_throws BoundsError c3[CartesianIndex(2, 3)]

    @testset "doubly periodic" begin
        c = PeriodicArray(t3)
        dc = PeriodicArray(c)

        @test all(c[i, j, k] == dc[i, j, k] for i in -5:5, j in -5:5, k in -5:5)
        @test all(c[i] == dc[i] for i in -50:50)
    end
end

@testset "circshift" begin
    @testset "1D" begin
        data = [1, 2, 3, 4, 5]
        a = PeriodicVector(data)
        @test circshift(a, 1) == PeriodicVector([5, 1, 2, 3, 4])
        @test circshift(a, -1) == PeriodicVector([2, 3, 4, 5, 1])
        @test circshift(a, 0) == a
        @test circshift(a, length(a)) == a
        for s in (-3, -1, 0, 2, 5)
            cs = circshift(a, s)
            @test all(cs[i] == a[i - s] for i in -20:20)
        end
    end

    @testset "2D" begin
        data = [1 2 3; 4 5 6]
        a = PeriodicMatrix(data)
        for s in ((0, 0), (1, 0), (0, 1), (1, 2), (-1, -1))
            cs = circshift(a, s)
            @test all(cs[i, j] == a[i - s[1], j - s[2]] for i in -5:5, j in -5:5)
        end
    end

    @testset "AbstractVector shifts" begin
        a = PeriodicVector([1, 2, 3, 4, 5])
        @test circshift(a, [2]) == circshift(a, 2)
        @test circshift(a, [-1]) == circshift(a, -1)

        b = PeriodicMatrix([1 2 3; 4 5 6])
        for s in ((0, 0), (1, 0), (0, 1), (1, 2))
            cs = circshift(b, collect(s))
            @test all(cs[i, j] == b[i - s[1], j - s[2]] for i in -5:5, j in -5:5)
        end
    end

    @testset "circshift! 3-arg" begin
        a = PeriodicVector([1, 2, 3, 4, 5])
        dest = similar(a)
        circshift!(dest, a, 2)
        @test dest == circshift(a, 2)
        @test parent(a) == [1, 2, 3, 4, 5]

        # empty tuple: no shift
        dest2 = similar(a)
        circshift!(dest2, a, ())
        @test dest2 == a

        # AbstractVector shifts
        dest3 = similar(a)
        circshift!(dest3, a, [2])
        @test dest3 == circshift(a, 2)
    end

    @testset "circshift! in-place" begin
        a = PeriodicVector([1, 2, 3, 4, 5])
        expected = circshift(a, 2)
        circshift!(a, 2)
        @test a == expected
    end

    @testset "circshift! 2D in-place" begin
        b = PeriodicMatrix([1 2 3; 4 5 6])
        expected = circshift(b, (1, 2))
        circshift!(b, (1, 2))
        @test b == expected
    end
end

@testset "reverse" begin
    @testset "1D" begin
        a = PeriodicVector([1, 2, 3, 4, 5])
        ra = reverse(a)
        @test parent(ra) == [5, 4, 3, 2, 1]
        @test ra[1] == a[5]
        @test ra[3] == a[3]
        # periodic: ra[i] == a[n+1-i] for all i
        @test all(ra[i] == a[6 - i] for i in -20:20)
    end

    @testset "2D full" begin
        b_arr = [1 2 3; 4 5 6]
        b = PeriodicMatrix(b_arr)
        rb = reverse(b)
        @test parent(rb) == reverse(b_arr)
        @test all(rb[i, j] == b[3 - i, 4 - j] for i in -5:5, j in -5:5)
    end

    @testset "2D partial" begin
        b_arr = [1 2 3; 4 5 6]
        b = PeriodicMatrix(b_arr)

        rb1 = reverse(b; dims = 1)
        @test parent(rb1) == reverse(b_arr; dims = 1)
        @test all(rb1[i, j] == b[3 - i, j] for i in -5:5, j in -5:5)

        rb2 = reverse(b; dims = 2)
        @test parent(rb2) == reverse(b_arr; dims = 2)
        @test all(rb2[i, j] == b[i, 4 - j] for i in -5:5, j in -5:5)
    end
end

@testset "repeat" begin
    @testset "1D" begin
        a = PeriodicVector([1, 2, 3])

        # outer as scalar — identity fmap tiles data unchanged
        ar = repeat(a; outer = 2)
        @test parent(ar) == [1, 2, 3, 1, 2, 3]
        @test length(ar) == 6

        # outer as tuple
        ar2 = repeat(a; outer = (2,))
        @test parent(ar2) == parent(ar)

        # inner repetition
        ai = repeat(a; inner = 2)
        @test parent(ai) == [1, 1, 2, 2, 3, 3]
        @test length(ai) == 6

        # combined inner + outer
        aio = repeat(a; inner = 2, outer = 3)
        @test length(aio) == 18
        @test parent(aio) == repeat(parent(ai); outer = 3)
    end

    @testset "2D" begin
        b_arr = [1 2; 3 4; 5 6]
        b = PeriodicMatrix(b_arr)

        # outer repetition
        br = repeat(b; outer = (2, 3))
        @test size(br) == (6, 6)
        @test parent(br) == repeat(b_arr; outer = (2, 3))

        # inner repetition
        bi = repeat(b; inner = (1, 2))
        @test parent(bi) == repeat(b_arr; inner = (1, 2))
        @test size(bi) == (3, 4)
    end
end

@testset "offset indices" begin
    i = OffsetArray(1:5, -3)
    a = PeriodicArray(i)
    @test axes(a) == axes(i)
    @test a[1] == 4
    @test a[10] == a[-10] == a[0] == 3
    @test a[-2:7] == [1:5; 1:5]
    @test a[0:9] == [3:5; 1:5; 1:2]
    @test a[1:10][-10] == 3
    @test a[i] == OffsetArray([4, 5, 1, 2, 3], -3)

    @testset "type stability" begin
        @test @inferred(similar(a)) isa PeriodicVector

        b = PeriodicVector([1, 2, 3, 4, 5])
        @test @inferred(similar(b, 3:5)) isa PeriodicVector
    end

    circ_a = circshift(a, 3)
    @test axes(circ_a) == axes(a)
    @test circ_a[1:5] == 1:5

    j = OffsetArray([true, false, true], 1)
    @test a[j] == [5, 2]

    data = reshape(1:9, 3, 3)
    a = PeriodicArray(OffsetArray(data, -1, -1))
    @test collect(a) == data
    @test all(a[x, y] == data[mod1(x + 1, 3), mod1(y + 1, 3)] for x in -10:10, y in -10:10)
    @test a[i, 1] == PeriodicArray(OffsetArray([5, 6, 4, 5, 6], -2:2))
    @test a[CartesianIndex.(i, i)] == PeriodicArray(OffsetArray([5, 9, 1, 5, 9], -2:2))
    @test a[a .> 4] == 5:9
end
