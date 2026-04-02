using PeriodicArrays
using PeriodicArrays: mapped_ref, MappedRef, PeriodicArrayStyle
using Base.Broadcast: BroadcastStyle, DefaultArrayStyle
using Test

@testset "broadcast" begin
    @testset "BroadcastStyle combination rules" begin
        s1 = PeriodicArrayStyle{1}()
        s2 = PeriodicArrayStyle{2}()
        sd1 = DefaultArrayStyle{1}()
        sd2 = DefaultArrayStyle{2}()

        # two PeriodicArrayStyles: result has max dimensionality
        @test BroadcastStyle(s1, s2) === PeriodicArrayStyle{2}()
        @test BroadcastStyle(s2, s1) === PeriodicArrayStyle{2}()
        @test BroadcastStyle(s1, s1) === PeriodicArrayStyle{1}()

        # PeriodicArrayStyle with DefaultArrayStyle
        @test BroadcastStyle(s1, sd2) === PeriodicArrayStyle{2}()
        @test BroadcastStyle(sd2, s1) === PeriodicArrayStyle{2}()
        @test BroadcastStyle(s2, sd1) === PeriodicArrayStyle{2}()
        @test BroadcastStyle(sd1, s2) === PeriodicArrayStyle{2}()
    end

    @testset "BroadcastStyle from array type" begin
        v = PeriodicVector([1, 2, 3])
        m = PeriodicMatrix([1 2; 3 4])
        @test BroadcastStyle(typeof(v)) === PeriodicArrayStyle{1}()
        @test BroadcastStyle(typeof(m)) === PeriodicArrayStyle{2}()
    end

    @testset "broadcast result type — identity fmap" begin
        v = PeriodicVector([1, 2, 3])
        m = PeriodicMatrix([1 2 3; 4 5 6])

        # 1D broadcast preserves PeriodicVector
        r1 = v .+ 1
        @test r1 isa PeriodicVector{Int64}
        @test r1 == PeriodicVector([2, 3, 4])

        # 2D broadcast preserves PeriodicMatrix
        r2 = m .* 2
        @test r2 isa PeriodicMatrix{Int64}
        @test r2 == PeriodicMatrix([2 4 6; 8 10 12])

        # scalar-first commutative form
        r3 = 10 .+ v
        @test r3 isa PeriodicVector{Int64}
        @test r3 == PeriodicVector([11, 12, 13])
    end

    @testset "broadcast result type — non-trivial fmap" begin
        f(x, shift::Vararg{Int}) = x + 10 * sum(shift)
        v = PeriodicVector([1, 2, 3], f)
        m = PeriodicMatrix([1 2; 3 4], f)

        r1 = v .+ 0
        @test r1 isa PeriodicVector{Int64}
        @test r1.fmap === f

        r2 = m .+ 0
        @test r2 isa PeriodicMatrix{Int64}
        @test r2.fmap === f

        # scalar-first
        r3 = 0 .+ v
        @test r3 isa PeriodicVector{Int64}
        @test r3.fmap === f
    end

    @testset "broadcast 2D × 1D (shape promotion)" begin
        m = PeriodicMatrix([1 2 3; 4 5 6])       # 2×3
        v = PeriodicVector([10, 20, 30])           # length-3 row vector view via reshape
        r = m .+ reshape(v, 1, 3)
        @test r isa PeriodicMatrix{Int64}
        @test r == PeriodicMatrix([11 22 33; 14 25 36])
    end

    @testset "in-place broadcast .=" begin
        a = PeriodicVector([1, 2, 3])
        b = similar(a)
        b .= a .+ 10
        @test b == PeriodicVector([11, 12, 13])
        @test b isa PeriodicVector{Int64}
    end

    @testset "_find_pa — nested Broadcasted" begin
        # exercises the recursive Broadcasted branch of _find_pa
        v = PeriodicVector([1, 2, 3])
        r = (v .+ 1) .* 2
        @test r isa PeriodicVector{Int64}
        @test r == PeriodicVector([4, 6, 8])
    end
end

@testset "mapped_ref" begin
    # fmap: x + shift, imap: x - shift  (NegatedShiftMap default)
    f(x, shift::Vararg{Int}) = x .+ sum(shift)

    @testset "in-bounds returns raw element" begin
        data = [ones(2, 2), 2 * ones(2, 2), 3 * ones(2, 2)]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 2)   # in-bounds: shift == 0
        @test ref === parent(x)[2]   # identity — no MappedRef wrapper
    end

    @testset "out-of-bounds returns MappedRef" begin
        data = [ones(2, 2), 2 * ones(2, 2)]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 3)   # wraps parent(x)[1] with shift=(1,)
        @test ref isa PeriodicArrays.MappedRef
    end

    @testset "MappedRef size and parent" begin
        data = [zeros(3, 4)]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 2)   # out-of-bounds: shift=(1,)
        @test size(ref) == (3, 4)
        @test parent(ref) === parent(x)[1]
    end

    @testset "getindex applies fmap" begin
        mat = [10.0 20.0; 30.0 40.0]
        data = [mat]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 2)   # shift=(1,)
        @test ref[1, 1] == 10.0 + 1   # fmap adds shift sum
        @test ref[2, 2] == 40.0 + 1
    end

    @testset "setindex! applies imap and writes back" begin
        mat = zeros(2, 2)
        data = [mat]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 2)   # shift=(1,), imap subtracts shift
        ref[1, 1] = 100.0         # stores imap(100, 1) = 99 into mat[1,1]
        @test mat[1, 1] == 99.0
        # reading back through ref applies fmap: 99 + 1 == 100
        @test ref[1, 1] == 100.0
        # reading through x at the out-of-bounds index also gives 100
        @test x[2][1, 1] == 100.0
    end

    @testset "setindex! return value" begin
        data = [zeros(2, 2)]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 2)
        ret = (ref[1, 2] = 42.0)
        @test ret == 42.0
    end

    @testset "mutation round-trip" begin
        # A full getindex→setindex! round-trip via mapped_ref must be lossless.
        mat = [1.0 2.0; 3.0 4.0]
        data = [copy(mat)]
        x = PeriodicVector(data, f)
        ref = mapped_ref(x, 2)

        for I in CartesianIndices(mat)
            original = mat[I]
            # fmap(original, 1) is what getindex would return
            observed = ref[I]
            @test observed == original + 1
            # write it back: imap(observed, 1) == original
            ref[I] = observed
            @test parent(x)[1][I] == original
        end
    end

    @testset "2D PeriodicMatrix element access" begin
        # PeriodicArray of matrices, indexed with two periodic indices
        f2(x, s1::Int, s2::Int) = x .+ s1 .+ s2
        data = [fill(Float64(i + 3 * j), 2, 2) for i in 1:3, j in 1:3]
        x = PeriodicMatrix(data, f2)

        # in-bounds
        ref_ib = mapped_ref(x, 2, 2)
        @test ref_ib === parent(x)[2, 2]

        # out-of-bounds in first dimension
        ref_oob = mapped_ref(x, 4, 1)   # shift=(1,0)
        @test ref_oob isa PeriodicArrays.MappedRef
        @test ref_oob[1, 1] == parent(x)[1, 1][1, 1] + 1
    end

    @testset "custom imap" begin
        f_fwd(x, shift::Vararg{Int}) = x .* (1 + sum(shift))
        f_inv(x, shift::Vararg{Int}) = x ./ (1 + sum(shift))
        data = [fill(2.0, 2, 2)]
        x = PeriodicVector(data, f_fwd, f_inv)
        ref = mapped_ref(x, 2)   # shift=(1,)
        # getindex: fmap(2.0, 1) = 2.0 * 2 = 4.0
        @test ref[1, 1] == 4.0
        # setindex!: imap(8.0, 1) = 8.0 / 2 = 4.0 stored
        ref[1, 1] = 8.0
        @test parent(x)[1][1, 1] == 4.0
    end
end
