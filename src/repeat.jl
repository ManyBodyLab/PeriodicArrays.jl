function Base.repeat(A::PeriodicArray{T, N}; inner = nothing, outer = nothing) where {T, N}
    map = A.map
    # If no outer repetition is requested, just repeat the parent array as usual
    A_new = repeat(parent(A); inner = inner)

    if !isnothing(outer)
        # allow passing a single integer or a tuple/ntuple for per-dimension repeats
        if isa(outer, Number)
            outer = ntuple(i -> Int(outer), N)
        else
            outer = ntuple(i -> Int(outer[i]), N)
        end

        # if `inner` was provided, A_new already contains the repeated parent
        base = A_new
        axs = axes(base)
        ps = size(base)
        newsize = ntuple(i -> ps[i] * outer[i], N)

        # create a tiled parent filled with translated values from `map`
        A_tiled = similar(base, newsize)
        tile_ranges = ntuple(i -> 0:(outer[i] - 1), N)
        for tile in CartesianIndices(tile_ranges)
            shifts = Tuple(Int(tile[i]) for i in 1:N)
            for pos in CartesianIndices(base)
                tgt = ntuple(i -> tile[i] * ps[i] + (pos[i] - firstindex(axs[i]) + 1), N)
                @inbounds A_tiled[tgt...] = map(base[pos], shifts...)
            end
        end

        @inline function map_new(x, shift::Vararg{Integer, N})
            # shifts passed to this map refer to super-cell shifts; amplify
            # by `outer` to convert them to original unit-cell shifts.
            amplified = ntuple(i -> shift[i] * outer[i], N)
            return map(x, amplified...)
        end

        imap_new = NegatedShiftMap(map_new)
        return PeriodicArray(A_tiled, map_new, imap_new)
    end

    return PeriodicArray(A_new, map, A.imap)
end
