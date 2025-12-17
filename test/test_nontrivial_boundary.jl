using PeriodicArrays
using Test
using OffsetArrays

f1(x,shift::Vararg{Int,N}) where {N} = x + sum(shift)
f2(x,shift::Vararg{Int,N}) where {N} = x + shift[1]
struct TestTranslation
end
function (f::TestTranslation)(x, shift::Vararg{Int,N}) where {N}
    return x - sum(shift)
end
f3 = TestTranslation()
translation_functions = [f1, f2, f3]

for f in translation_functions
    @testset "construction" begin
        @testset "construction ($T)" for T = (Float64, Int)
            data = rand(T,10)
            arrays = [PeriodicVector(data, f), PeriodicVector{T}(data, f),
                    PeriodicArray(data, f), PeriodicArray{T}(data, f), PeriodicArray{T,1}(data, f)]
            @test all(a == first(arrays) for a in arrays)
            @test all(a isa PeriodicVector{T,Vector{T}} for a in arrays)
        end

        @testset "matrix construction" begin
            data = zeros(Float64, 2, 2)
            ref = PeriodicMatrix(data, f)
            @test PeriodicArray{Float64, 2}(data, f) == ref
            @test PeriodicMatrix{Float64}(data, f) == ref
            @test PeriodicMatrix{Float64, Array{Float64, 2}}(data, f) == ref
            @test PeriodicMatrix{Float64, Matrix{Float64}}(data, f) == ref
        end
    end
    @testset "type stability" begin
        @testset "type stability $(n)d" for n in 1:10
            a = PeriodicArray(fill(1, ntuple(_->1, n)), f)
            @test @inferred(a[1]) isa Int64
            @test @inferred(a[[1]]) isa PeriodicVector{Int64}
            @test @inferred(a[[1]']) isa PeriodicArray{Int64,2}
            @test @inferred(axes(a)) isa Tuple{Vararg{AbstractUnitRange}}
            @test @inferred(similar(a)) isa typeof(a)
            @test @inferred(similar(a, Float64, Int8.(size(a)))) isa PeriodicArray{Float64}
            @test @inferred(a[a]) isa typeof(a)
        end
    end
    @testset "display" begin
        @testset "display $(n)d" for n in 1:3
            data = rand(Int64, ntuple(_->3, n))
            v1 = PeriodicArray(data, f)
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
        v1 = PeriodicVector(data, f)

        @test size(v1, 1) == 5
        @test parent(v1) == data
        @test typeof(v1) == PeriodicVector{Int64,Vector{Int64},typeof(f)}
        @test isa(v1, PeriodicVector)
        @test isa(v1, AbstractVector{Int})
        @test !isa(v1, AbstractVector{String})

        @test IndexStyle(v1) == IndexStyle(typeof(v1)) == IndexLinear()
        @test all(e in data for e in v1)
        @test all(e in v1 for e in data)

        v1copy = copy(v1)
        v1_2 = v1[2]
        v1[2] = 0
        v1[3] = 0
        @test v1[2] == v1[3] == 0
        @test v1copy[2] == v1_2
        @test v1copy[7] == f(v1_2, 1)
        @test_throws MethodError v1[2] = "Hello"

        v2 = PeriodicVector("abcde", 5)

        @test prod(v2) == "abcde"^5

        @testset "empty/empty!" begin
            v1 = PeriodicVector([1,2,3], f)
            @test empty(v1) isa PeriodicVector{Int64}
            @test empty(v1, Float64) isa PeriodicVector{Float64}
            v1 == PeriodicVector([], f)
            # `isempty` can be used to implement `size` method.
            @test isempty(empty(v1))

            v2 = PeriodicVector("abcde", 5)
            @test empty!(v2) isa PeriodicVector{String}
            @test isempty(v2)
        end

        @testset "resize!" begin
            @test_throws ArgumentError("new length must be ≥ 0") resize!(PeriodicVector([], f), -2)
            v = PeriodicVector([1,2,3,4,5,6,7], f)
            resize!(v, 3)
            @test length(v) == 3

            # ensure defining `resize!` induces `push!` and `append!` methods
            @testset "push!" begin
                v = PeriodicVector([1,2,3], f)
                push!(v, 42)
                @test v == PeriodicVector([1,2,3,42], f)
                push!(v, -9, -99, -999)
                @test v == PeriodicVector([1,2,3,42, -9, -99, -999], f)
            end

            @testset "append!" begin
                v1 = PeriodicVector([1,2,3], f)
                append!(v1, [-9, -99, -999])
                @test v1 == PeriodicVector([1,2,3, -9, -99, -999], f)

                v2 = PeriodicVector([1,2,3], f)
                append!(v2, PeriodicVector([-1,-2], f))
                @test v2 == PeriodicVector([1,2,3,-1,-2], f)

                v3 = PeriodicVector([1,2,3], f)
                append!(v3, [4, 5], [6])
                @test v3 == PeriodicVector([1,2,3,4,5,6], f)

                v4 = PeriodicVector([1,2,3], f)
                o4 = OffsetVector([-1,-2,-3], -2:0)
                append!(v4, o4)
                @test v4 == PeriodicVector([1,2,3,-1,-2,-3], f)

                v5 = PeriodicVector([1,2,3], f)
                o5 = OffsetVector([-1,-2,-3], -2:0)
                append!(v5, o5, -4)
                @test v5 == PeriodicVector([1,2,3,-1,-2,-3,-4], f)
            end
        end

        @testset "pop!" begin
            v1 = PeriodicVector([1,2,3,42], f)
            pop!(v1) == 42
            @test v1 == PeriodicVector([1,2,3], f)

            v2 = PeriodicVector([1], f)
            pop!(v2) == 1
            @test v2 == PeriodicVector([], f)
            @test isempty(v2)
            @test_throws ArgumentError("array must be non-empty") pop!(v2)
        end

        @testset "sizehint!" begin
            v = PeriodicVector([1,2,3,4,5,6,7], f)
            resize!(v, 1)
            sizehint!(v, 1)
            @test length(v) == 1
        end

        @testset "deleteat!" begin
            @test deleteat!(PeriodicVector([1, 2, 3], f), 2) == PeriodicVector([1, 3], f)
            @test deleteat!(PeriodicVector([1, 2, 3], f), 5) == PeriodicVector([1, 3], f)
            @test deleteat!(PeriodicVector([1, 2, 3], f), 4) == PeriodicVector([2, 3], f)
            @test deleteat!(PeriodicVector([1, 2, 3], f), 0) == PeriodicVector([1, 2], f)
            @test deleteat!(PeriodicVector([1, 2, 3, 4], f), 1:5:10) == PeriodicVector([3, 4], f)
            @test deleteat!(PeriodicVector([1, 2, 3, 4], f), [1, 5]) == PeriodicVector([2, 3, 4], f)
            @test deleteat!(PeriodicVector([1, 2, 3, 4], f), (1, 5)) == PeriodicVector([2, 3, 4], f)
            @test deleteat!(PeriodicVector([1, 2, 3, 4], f), (1, 6)) == PeriodicVector([3, 4], f)
            @test deleteat!(PeriodicVector([1, 2, 3, 4], f), (1, 3, 5)) == PeriodicVector([2, 4], f)
            @test deleteat!(PeriodicVector([1, 2, 3, 4], f), (1, 5, 7)) == PeriodicVector([2, 4], f)
        end

        @testset "insert!" begin
            @test insert!(PeriodicVector([1, 2, 3], f), 2, 4) == PeriodicVector([1, 4, 2, 3], f)
            @test insert!(PeriodicVector([1, 2, 3], f), 5, 4) == PeriodicVector([1, 4, 2, 3], f)
            @test insert!(PeriodicVector([1, 2, 3], f), 4, 4) == PeriodicVector([4, 1, 2, 3], f)
            @test insert!(PeriodicVector([1, 2, 3], f), 0, 4) == PeriodicVector([1, 2, 4, 3], f)
        end

        @testset "doubly periodic" begin
            a = PeriodicVector([1, 2, 3, 4, 5], f)
            b = PeriodicVector(a, f)

            @test all(a[i] == b[i] for i in -50:50)
        end

        @testset "type stability" begin
            v3 = @inferred(map(x -> x+1, PeriodicArray([1, 2, 3, 4], f)))
            @test v3 isa PeriodicVector{Int64}
            @test v3 == PeriodicArray([2, 3, 4, 5], f)
            @test similar(v3, Base.OneTo(4)) isa typeof(v3)

            v4 = @inferred(PeriodicArray([1, 2, 3, 4], f) .+ 1)
            @test v4 isa PeriodicVector{Int64}
            @test v4 == PeriodicArray([2, 3, 4, 5], f)

            v5 = v4 .> 3
            @test v5 isa PeriodicVector{Bool, BitVector}
            @test v5 == PeriodicArray([0, 0, 1, 1], f)
        end
    end

    @testset "matrix" begin
        b_arr = [2 4 6 8; 10 12 14 16; 18 20 22 24]
        a1 = PeriodicMatrix(b_arr, f)
        @test size(a1) == (3, 4)
        @test parent(a1) == b_arr

        @test a1[2, 3] == 14
        @test a1[2, Int32(3)] == 14
        a1[2, 3] = 17
        @test a1[2, 3] == 17
        @test a1[-1, 7] == f(17, -1, 1)
        @test a1[CartesianIndex(-1, 7)] == f(17, -1, 1)
        @test a1[-1:5, 4:10][1, 4] == f(17, -1, 1)
        a1[CartesianIndex(-2, 7)] = 99
        @test f(a1[1, 3], -1, 1) == 99

        @test IndexStyle(a1) == IndexStyle(typeof(a1)) == IndexCartesian()
        @test a1[3] == a1[3,1]
        @test a1[Int32(4)] == a1[1,2]

        @test a1[2, 3, 1] == 17 # trailing index
        @test a1[2, 3, 99] == 17
        @test a1[2, 3, :] == [17]

        @test !isa(a1, PeriodicVector)
        @test !isa(a1, AbstractVector)
        @test isa(a1, AbstractMatrix)
        @test isa(a1, AbstractArray)

        @test size(reshape(a1, (2, 2, 3))) == (2, 2, 3)

        a2 = PeriodicMatrix(4, (2, 3), f)
        @test isa(a2, PeriodicMatrix{Int})
        @test isa(a2, PeriodicArray{Int, 2})
        @test_throws BoundsError a2[1000]
        @test_throws BoundsError a2[1000] = 14

        a3 = @inferred(a2 .+ 1)
        @test a3 isa PeriodicMatrix{Int64}
        @test a3 isa PeriodicArray{Int64, 2}
        @test a3 == PeriodicArray(5, (2, 3), f)

        a3[3] = -12
        @test a3[3] == -12

        @testset "doubly periodic" begin
            a = PeriodicMatrix(b_arr, f)
            da = PeriodicMatrix(a, f)
            d2a = PeriodicMatrix(a)
            @test da isa PeriodicMatrix
            @test d2a isa PeriodicMatrix
            @test all(a[i, j] == da[i, j] for i in -20:20, j in -20:20)
            @test all(a[i, j] == d2a[i, j] for i in -20:20, j in -20:20)
        end
    end

    @testset "3-array" begin
        t3 = collect(reshape(1:24, 2,3,4))
        c3 = PeriodicArray(t3, f)

        @test parent(c3) == t3

        @test c3[1,3,3] == f(c3[3,3,3],-1,0,0) == f(c3[3,3,7],-1,0,-1) == f(c3[3,3,7,1],-1,0,-1)

        @test c3[3,3,7] == f(c3[1,3,3],1,0,1)

        @test c3[3, CartesianIndex(3,7)] == f(c3[1,3,3],1,0,1)
        @test c3[Int32(3), CartesianIndex(3,7)] == f(c3[1,3,3],1,0,1)

        @test vec(c3[:, [CartesianIndex()], 1, 5]) == map(x->f(x,0,0,1), vec(t3[:, 1, 1]))

        @test IndexStyle(c3) == IndexStyle(typeof(c3)) == IndexCartesian()

        @test_throws BoundsError c3[2,3] # too few indices
        @test_throws BoundsError c3[CartesianIndex(2,3)]
        @test_throws BoundsError c3[30]

        @testset "doubly periodic" begin
            c = PeriodicArray(t3, f)
            dc = PeriodicArray(c, f)

            @test all(c[i, j, k] == dc[i, j, k] for i in -5:5, j in -5:5, k in -5:5)
        end
    end

    @testset "offset indices" begin
        i = OffsetArray(1:5,-3)
        a = PeriodicArray(i, f)
        @test axes(a) == axes(i)
        @test a[1] == 4
        @test f(a[10],-2) == f(a[-10],2) == a[0] == 3
        @test a[1:10][-10] == 3
        @test a[i] == OffsetArray([4,5,f(1,1),f(2,1),f(3,1)],-3)

        @testset "type stability" begin
            @test @inferred(similar(a)) isa PeriodicVector

            b = PeriodicVector([1, 2, 3, 4, 5])
            @test @inferred(similar(b, 3:5)) isa PeriodicVector
        end

        circ_a = circshift(a,3)
        @test axes(circ_a) == axes(a)
        @test circ_a[1:5] == [1,2,f(3,1),f(4,1),f(5,1)]

        j = OffsetArray([true,false,true],1)
        @test a[j] == [5,f(2,1)]

        data = reshape(1:9,3,3)
        a = PeriodicArray(OffsetArray(data,-1,-1), f)
        @test collect(a) == data
        @test all(a[x,y] == f(data[mod1(x+1,3),mod1(y+1,3)], fld(x,3), fld(y,3)) for x=-10:10, y=-10:10)
        @test a[i,1] == PeriodicArray(OffsetArray([5,6,f(4,1,0),f(5,1,0),f(6,1,0)],-2:2), f)
        @test a[CartesianIndex.(i,i)] == PeriodicArray(OffsetArray([5,9,f(1,1,1),f(5,1,1),f(9,1,1)],-2:2), f)
        # TODO: Figure out how to fix indexing for non-trivial f
        #@test a[a .> 4] == 5:9
    end

    @testset "repeat 1D" begin
        a = PeriodicArray([1, 2, 3], f)
        # outer as scalar
        ar = repeat(a; outer = 2)
        base = parent(a)
        # expected tiled parent: tiles over shifts 0,1
        expected = vcat([f(base[i], 0) for i in eachindex(base)]..., [f(base[i], 1) for i in eachindex(base)]...)
        @test parent(ar) == expected
        @test size(parent(ar)) == (length(base) * 2,)

        val = 5
        @test ar.map(val, 1) == a.map(val, 2)
        @test ar.map(val, 3) == a.map(val, 6)

        # inner repetition
        ai = repeat(a; inner = 2)
        @test parent(ai) == repeat(parent(a); inner = 2)
        @test size(parent(ai)) == (length(base) * 2,)

        # combined inner+outer
        aio = repeat(a; inner = 2, outer = 3)
        @test size(parent(aio)) == (length(base) * 2 * 3,)

        # outer as tuple (1D tuple)
        ar2 = repeat(a; outer = (2,))
        @test parent(ar2) == expected
    end

    @testset "repeat 2D" begin
        b = PeriodicArray(reshape(1:6, 3, 2), f)
        o1, o2 = 2, 3
        br = repeat(b; outer = (o1, o2))
        base = parent(b)
        expected2 = similar(base, size(base, 1) * o1, size(base, 2) * o2)
        for t2 in 0:(o2 - 1), t1 in 0:(o1 - 1)
            for pos in CartesianIndices(base)
                tgt = (
                    t1 * size(base, 1) + (pos[1] - firstindex(axes(base, 1)) + 1),
                    t2 * size(base, 2) + (pos[2] - firstindex(axes(base, 2)) + 1),
                )
                @inbounds expected2[tgt...] = f(base[pos], t1, t2)
            end
        end
        @test parent(br) == expected2
        @test size(parent(br)) == (size(base, 1) * o1, size(base, 2) * o2)

        @test br.map(1, 1, 2) == b.map(1, 2, 6)
        @test br.map(7, 0, 1) == b.map(7, 0, 3)

        # inner repetition in 2D
        bi = repeat(b; inner = (2, 1))
        @test parent(bi) == repeat(parent(b); inner = (2, 1))
        @test size(parent(bi)) == (size(base, 1) * 2, size(base, 2) * 1)
    end

    @testset "reverse" begin
        a = PeriodicArray([1, 2, 3], f)
        ra = reverse(a)
        @test parent(ra) == reverse(parent(a))
        @test ra[1] == a[3]
        @test ra[2] == a[2]

        # 2D reverse across first dimension
        b = PeriodicArray(reshape(1:6, 3, 2), f)
        rb1 = reverse(b; dims = 1)
        @test parent(rb1) == reverse(parent(b); dims = 1)
        @test all(rb1[i, j] == b[4 - i, j] for i in -10:10, j in -10:10)

        # full reverse
        rb = reverse(b)
        @test parent(rb) == reverse(parent(b))
        @test all(rb[i, j] == b[4 - i, 3 - j] for i in -10:10, j in -10:10)
    end
end
