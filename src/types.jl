identity_map(x, ::Vararg{Any}) = x
const _identity_map_type = typeof(identity_map)

struct NegatedShiftMap{F}
    map::F
end
(m::NegatedShiftMap)(x, shifts::Vararg{Integer}) = m.map(x, ntuple(i -> -shifts[i], length(shifts))...)

"""
    PeriodicArray{T, N, A, F, G} <: AbstractArray{T, N}

`N`-dimensional array backed by an `AbstractArray{T, N}` of type `A` with fixed size
and periodic indexing as defined by `map` and `imap`.

    array[index...] == map(array[mod1.(index, size)...], fld.(index .- 1, size)...)

`imap` is the inverse map used for `setindex!`, defaulting to `map` with negated shifts.
"""
struct PeriodicArray{T, N, A <: AbstractArray{T, N}, F, G} <: AbstractArray{T, N}
    data::A
    map::F
    imap::G
    function PeriodicArray{T}(data::A, map::F, imap::G) where {A <: AbstractArray{T, N}, F, G} where {T, N}
        new{T, N, A, F, G}(data, map, imap)
    end
    function PeriodicArray{T, N}(data::A, map::F, imap::G) where {A <: AbstractArray{T, N}, F, G} where {T, N}
        new{T, N, A, F, G}(data, map, imap)
    end
    function PeriodicArray{T, N, A}(data::A, map::F, imap::G) where {A <: AbstractArray{T, N}, F, G} where {T, N}
        new{T, N, A, F, G}(data, map, imap)
    end
end

PeriodicArray{T}(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} =
    PeriodicArray{T}(data, map, _default_imap(map))
PeriodicArray{T, N}(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} =
    PeriodicArray{T, N}(data, map, _default_imap(map))
PeriodicArray{T, N, A}(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} =
    PeriodicArray{T, N, A}(data, map, _default_imap(map))

_default_imap(map::_identity_map_type) = map
_default_imap(map) = NegatedShiftMap(map)

"""
    PeriodicArray(data, [map, [imap]])

Create a `PeriodicArray` backed by `data`.
`map` defaults to the identity map. `imap` defaults to `map` with negated shifts.
"""
PeriodicArray(data::A, map::F = identity_map, imap::G = _default_imap(map)) where {A <: AbstractArray{T, N}, F, G} where {T, N} = PeriodicArray{T, N}(data, map, imap)

PeriodicArray(arr::PeriodicArray, map::F = identity_map) where {F} = arr

"""
    PeriodicArray(def, size, [map])

Create a `PeriodicArray` of size `size` filled with value `def`.
`map` is optional and defaults to the identity map.
"""
PeriodicArray(def::T, size, map::F = identity_map) where {T, F} = PeriodicArray(fill(def, size), map)

"""
    PeriodicVector{T, A, F, G} <: AbstractVector{T}

One-dimensional array backed by an `AbstractArray{T, 1}` of type `A` with fixed size and periodic indexing.
Alias for [`PeriodicArray{T, 1, A, F, G}`](@ref).

    array[index] == map(array[mod1(index, length)], fld(index - 1, length))
"""
const PeriodicVector{T} = PeriodicArray{T, 1}

"""
    PeriodicMatrix{T, A, F, G} <: AbstractMatrix{T}

Two-dimensional array backed by an `AbstractArray{T, 2}` of type `A` with fixed size and periodic indexing.
Alias for [`PeriodicArray{T, 2, A, F, G}`](@ref).
"""
const PeriodicMatrix{T} = PeriodicArray{T, 2}

# Define constructors for PeriodicVector and PeriodicMatrix
PeriodicVector(args...) = PeriodicArray(args...)
PeriodicMatrix(args...) = PeriodicArray(args...)

Base.IndexStyle(::Type{PeriodicArray{T, N, A, F, G}}) where {T, N, A, F, G} = IndexCartesian()
Base.IndexStyle(::Type{<:PeriodicVector}) = IndexLinear()

@inline Base.size(arr::PeriodicArray) = size(arr.data)
@inline Base.axes(arr::PeriodicArray) = axes(arr.data)
@inline Base.parent(arr::PeriodicArray) = arr.data

@inline Base.iterate(arr::PeriodicArray, i...) = iterate(parent(arr), i...)

@inline Base.in(x, arr::PeriodicArray) = in(x, parent(arr))
@inline Base.copy(arr::PeriodicArray) = PeriodicArray(copy(parent(arr)), arr.map, arr.imap)

@inline Base.dataids(arr::PeriodicArray) = Base.dataids(parent(arr))

function Base.showarg(io::IO, arr::PeriodicArray, toplevel)
    print(io, ndims(arr) == 1 ? "PeriodicVector(" : "PeriodicArray(")
    Base.showarg(io, parent(arr), false)
    return print(io, ')')
end

@inline function _similar(arr::PeriodicArray, ::Type{T}, dims) where {T}
    return PeriodicArray(similar(parent(arr), T, dims), arr.map, arr.imap)
end
@inline function Base.similar(
        arr::PeriodicArray, ::Type{T}, dims::Tuple{Base.DimOrInd, Vararg{Base.DimOrInd}}
    ) where {T}
    return _similar(arr, T, dims)
end
# Ambiguity resolution with Base
@inline function Base.similar(arr::PeriodicArray, ::Type{T}, dims::Dims) where {T}
    return _similar(arr, T, dims)
end
@inline function Base.similar(
        arr::PeriodicArray, ::Type{T}, dims::Tuple{Integer, Vararg{Integer}}
    ) where {T}
    return _similar(arr, T, dims)
end
@inline function Base.similar(
        arr::PeriodicArray, ::Type{T},
        dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}}
    ) where {T}
    return _similar(arr, T, dims)
end
