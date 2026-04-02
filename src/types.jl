identity_map(x, ::Vararg{Any}) = x
const _identity_map_type = typeof(identity_map)

struct NegatedShiftMap{F}
    fmap::F
end
(m::NegatedShiftMap)(x, shifts::Vararg{Integer}) = m.fmap(x, ntuple(i -> -shifts[i], length(shifts))...)

"""
    PeriodicArray{T, N, A, F, G} <: AbstractArray{T, N}

`N`-dimensional array backed by an `AbstractArray{T, N}` of type `A` with fixed size
and periodic indexing as defined by `fmap` and `imap`.

    array[index...] == fmap(array[mod1.(index, size)...], fld.(index .- 1, size)...)

`imap` is the inverse fmap used for `setindex!`, defaulting to `fmap` with negated shifts.
"""
struct PeriodicArray{T, N, A <: AbstractArray{T, N}, F, G} <: AbstractArray{T, N}
    data::A
    fmap::F
    imap::G
    function PeriodicArray{T}(data::A, fmap::F, imap::G) where {A <: AbstractArray{T, N}, F, G} where {T, N}
        return new{T, N, A, F, G}(data, fmap, imap)
    end
    function PeriodicArray{T, N}(data::A, fmap::F, imap::G) where {A <: AbstractArray{T, N}, F, G} where {T, N}
        return new{T, N, A, F, G}(data, fmap, imap)
    end
    function PeriodicArray{T, N, A}(data::A, fmap::F, imap::G) where {A <: AbstractArray{T, N}, F, G} where {T, N}
        return new{T, N, A, F, G}(data, fmap, imap)
    end
end

PeriodicArray{T}(data::A, fmap::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} =
    PeriodicArray{T}(data, fmap, _default_imap(fmap))
PeriodicArray{T, N}(data::A, fmap::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} =
    PeriodicArray{T, N}(data, fmap, _default_imap(fmap))
PeriodicArray{T, N, A}(data::A, fmap::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} =
    PeriodicArray{T, N, A}(data, fmap, _default_imap(fmap))

_default_imap(fmap::_identity_map_type) = fmap
_default_imap(fmap) = NegatedShiftMap(fmap)

"""
    PeriodicArray(data, [fmap, [imap]])

Create a `PeriodicArray` backed by `data`.
`fmap` defaults to the identity fmap. `imap` defaults to `fmap` with negated shifts.
"""
PeriodicArray(data::A, fmap::F = identity_map, imap::G = _default_imap(fmap)) where {A <: AbstractArray{T, N}, F, G} where {T, N} = PeriodicArray{T, N}(data, fmap, imap)

PeriodicArray(arr::PeriodicArray, fmap::F = identity_map) where {F} = arr

"""
    PeriodicArray(def, size, [fmap])

Create a `PeriodicArray` of size `size` filled with value `def`.
`fmap` is optional and defaults to the identity fmap.
"""
PeriodicArray(def::T, size, fmap::F = identity_map) where {T, F} = PeriodicArray(fill(def, size), fmap)

"""
    PeriodicVector{T, A, F, G} <: AbstractVector{T}

One-dimensional array backed by an `AbstractArray{T, 1}` of type `A` with fixed size and periodic indexing.
Alias for [`PeriodicArray{T, 1, A, F, G}`](@ref).

    array[index] == fmap(array[mod1(index, length)], fld(index - 1, length))
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

@inline function Base.getproperty(arr::PeriodicArray, name::Symbol)
    name === :map && return getfield(arr, :fmap)
    return getfield(arr, name)
end

@inline Base.size(arr::PeriodicArray) = size(arr.data)
@inline Base.axes(arr::PeriodicArray) = axes(arr.data)
@inline Base.parent(arr::PeriodicArray) = arr.data

@inline Base.iterate(arr::PeriodicArray, i...) = iterate(parent(arr), i...)

@inline Base.in(x, arr::PeriodicArray) = in(x, parent(arr))
@inline Base.copy(arr::PeriodicArray) = PeriodicArray(copy(parent(arr)), arr.fmap, arr.imap)

@inline Base.dataids(arr::PeriodicArray) = Base.dataids(parent(arr))

function Base.showarg(io::IO, arr::PeriodicArray, toplevel)
    print(io, ndims(arr) == 1 ? "PeriodicVector(" : "PeriodicArray(")
    Base.showarg(io, parent(arr), false)
    return print(io, ')')
end

@inline function _similar(arr::PeriodicArray, ::Type{T}, dims) where {T}
    return PeriodicArray(similar(parent(arr), T, dims), arr.fmap, arr.imap)
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
