function Base.reverse(arr::PeriodicArray{T, N, A, F}; dims = :) where {T, N, A, F}
    dims == Colon() && return _reverse(arr)
    return _reverse(arr, dims)
end

function _reverse(arr::PeriodicArray{T, N, A, F}) where {T, N, A, F}
    base = reverse(parent(arr))

    @inline function map_rev(x, shifts::Vararg{Integer, N})
        neg = ntuple(i -> -shifts[i], N)
        return arr.map(x, neg...)
    end

    return PeriodicArray(base, map_rev)
end

function _reverse(arr::PeriodicArray{T, N, A, F}, dims...) where {T, N, A, F}
    base = reverse(parent(arr); dims = dims)
    dimsset = Set(dims)

    @inline function map_rev(x, shifts::Vararg{Integer, N})
        adj = ntuple(i -> (i in dimsset) ? -shifts[i] : shifts[i], N)
        return arr.map(x, adj...)
    end

    return PeriodicArray(base, map_rev)
end
