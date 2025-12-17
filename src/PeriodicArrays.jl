"""
Arrays with fixed size and arbitrary boundary conditions.
"""
module PeriodicArrays

export PeriodicArray, PeriodicVector, PeriodicMatrix

identity_map(x, ::Vararg{Any}) = x
const _identity_map_type = typeof(identity_map)

"""
    PeriodicArray{T, N, A, F} <: AbstractArray{T, N}

`N`-dimensional array backed by an `AbstractArray{T, N}` of type `A` with fixed size 
and periodic indexing as defined by `map`.

    array[index...] == map(array[mod1.(index, size)...], fld.(index .- 1, size)...)
"""
struct PeriodicArray{T, N, A <: AbstractArray{T, N}, F} <: AbstractArray{T,N}
    data::A
    map::F
    PeriodicArray{T}(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} = new{T,N,A,F}(data, map)
    PeriodicArray{T,N}(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} = new{T,N,A,F}(data, map)
    PeriodicArray{T,N,A}(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} = new{T,N,A,F}(data, map)
end

"""
    PeriodicArray(data, [map])

Create a `PeriodicArray` backed by `data`.
`map` is optional and defaults to the identity map.
"""
PeriodicArray(data::A, map::F = identity_map) where {A <: AbstractArray{T, N}, F} where {T, N} = PeriodicArray{T,N}(data, map)


PeriodicArray(arr::PeriodicArray, map::F = identity_map) where {F} = arr

"""
    PeriodicArray(def, size, [map])

Create a `PeriodicArray` of size `size` filled with value `def`.
`map` is optional and defaults to the identity map.
"""
PeriodicArray(def::T, size, map::F = identity_map) where {T,F} = PeriodicArray(fill(def, size), map)

"""
    PeriodicVector{T, A, F} <: AbstractVector{T}

One-dimensional array backed by an `AbstractArray{T, 1}` of type `A` with fixed size and periodic indexing.
Alias for [`PeriodicArray{T, 1, A, F}`](@ref).

    array[index] == map(array[mod1(index, length)], fld(index - 1, length))
"""
const PeriodicVector{T} = PeriodicArray{T, 1}

"""
    PeriodicMatrix{T, A, F} <: AbstractMatrix{T}

Two-dimensional array backed by an `AbstractArray{T, 2}` of type `A` with fixed size and periodic indexing.
Alias for [`PeriodicArray{T, 2, A, F}`](@ref).
"""
const PeriodicMatrix{T} = PeriodicArray{T, 2}

# Define constructors for PeriodicVector and PeriodicMatrix 
PeriodicVector(args...) = PeriodicArray(args...)
PeriodicMatrix(args...) = PeriodicArray(args...)


Base.IndexStyle(::Type{PeriodicArray{T, N, A, F}}) where {T, N, A, F} = IndexCartesian()
Base.IndexStyle(::Type{<:PeriodicVector}) = IndexLinear()

function cell_position(arr::AbstractArray{T, N}, I::Vararg{Int, N}) where {T, N}
    axs = axes(arr)
    i_base = ntuple(N) do d
        ax = axs[d]
        len = length(ax)
        lo = firstindex(ax)
        # wrap I[d] into the axis range lo:lo+len-1
        lo + mod(I[d] - lo, len)
    end
    i_shift = ntuple(d -> fld(I[d] - i_base[d], length(axs[d])), N)
    return i_base, i_shift
end
function inverse_cell_position(arr::AbstractArray{T, N}, I::Vararg{Int, N}) where {T, N}
    axs = axes(arr)
    i_base = ntuple(N) do d
        ax = axs[d]
        len = length(ax)
        lo = firstindex(ax)
        # wrap I[d] into the axis range lo:lo+len-1
        lo + mod(I[d] - lo, len)
    end
    i_shift = ntuple(d -> -fld(I[d] - i_base[d], length(axs[d])), N)
    return i_base, i_shift
end

# Special case for trivial map (identical to CelledArrays.jl)
@inline function Base.getindex(
        arr::PeriodicArray{T, N, A, _identity_map_type}, i::Int
    ) where {A<:AbstractArray{T, N}} where {T, N}
    return @inbounds getindex(parent(arr), mod(i, eachindex(IndexLinear(), parent(arr))))
end
@inline function Base.setindex!(
        arr::PeriodicArray{T, N, A, _identity_map_type}, v, i::Int
    ) where {A <: AbstractArray{T, N}} where {T, N}
    @inbounds setindex!(parent(arr), v, mod(i, eachindex(IndexLinear(), parent(arr))))
end

@inline function Base.getindex(
        arr::PeriodicArray{T, N, A, F}, I::Vararg{Int, N}
    ) where {T, N, A, F}
    i_base, i_shift = cell_position(arr, I...)

    @inbounds v = getindex(parent(arr), i_base...)
    all(iszero, i_shift) && return v 
    return arr.map(v, i_shift...)
end
@inline function Base.setindex!(
        arr::PeriodicArray{T, N, A, F}, v, I::Vararg{Int, N}
    ) where {T,N,A,F}
    i_base, i_shift = inverse_cell_position(arr, I...)
    
    all(iszero, i_shift) && return @inbounds setindex!(parent(arr), v, i_base...)
    return @inbounds setindex!(parent(arr), arr.map(v, i_shift...), i_base...)
end

# Linear indexing is not well-defined outside of the first unit-cell
function Base.getindex(
        arr::PeriodicArray{T, N, A, F}, i::Int
    ) where {A <: AbstractArray{T, N}, F} where {T, N}
    if Base.checkbounds(Bool, parent(arr), i)
        return @inbounds getindex(parent(arr), i)
    end
    throw(BoundsError(arr, i))
end
function Base.setindex!(
        arr::PeriodicArray{T, N, A, F}, v, i::Int
    ) where {A <: AbstractArray{T, N}, F} where {T, N}
    if Base.checkbounds(Bool, parent(arr), i)
        return @inbounds setindex!(parent(arr), v, i)
    end
    throw(BoundsError(arr, i))
end

@inline Base.size(arr::PeriodicArray) = size(arr.data)
@inline Base.axes(arr::PeriodicArray) = axes(arr.data)
@inline Base.parent(arr::PeriodicArray) = arr.data

@inline Base.iterate(arr::PeriodicArray, i...) = iterate(parent(arr), i...)

@inline Base.in(x, arr::PeriodicArray) = in(x, parent(arr))
@inline Base.copy(arr::PeriodicArray) = PeriodicArray(copy(parent(arr)), arr.map)

@inline function Base.checkbounds(arr::PeriodicArray, I...)
    J = Base.to_indices(arr, I)
    length(J) == 1 || length(J) >= ndims(arr) || throw(BoundsError(arr, I))
    nothing
end

@inline function _similar(arr::PeriodicArray, ::Type{T}, dims) where T 
    return PeriodicArray(similar(parent(arr), T, dims), arr.map)
end
@inline function Base.similar(
        arr::PeriodicArray, ::Type{T}, dims::Tuple{Base.DimOrInd, Vararg{Base.DimOrInd}}
    ) where T 
    return _similar(arr, T, dims)
end
# Ambiguity resolution with Base
@inline function Base.similar(arr::PeriodicArray, ::Type{T}, dims::Dims) where T
    return _similar(arr, T, dims)
end
@inline function Base.similar(
        arr::PeriodicArray, ::Type{T}, dims::Tuple{Integer, Vararg{Integer}}
    ) where T
    return _similar(arr, T, dims)
end
@inline function Base.similar(
        arr::PeriodicArray, ::Type{T}, 
        dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}}
    ) where T
    return _similar(arr, T, dims)
end

@inline function Broadcast.BroadcastStyle(
        ::Type{PeriodicArray{T, N, A, F}}
    ) where {T, N, A, F} 
    return Broadcast.ArrayStyle{PeriodicArray{T, N, A, F}}()
end
@inline function Base.similar(
        bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{PeriodicArray{T, N, A, F}}}, ::Type{ElType}
    ) where {T, N, A, F, ElType} 
    return PeriodicArray(
        similar(convert(Broadcast.Broadcasted{typeof(Broadcast.BroadcastStyle(A))}, bc), ElType),
        bc.args[1].map
    )
end

@inline Base.dataids(arr::PeriodicArray) = Base.dataids(parent(arr))

function Base.showarg(io::IO, arr::PeriodicArray, toplevel)
    print(io, ndims(arr) == 1 ? "PeriodicVector(" : "PeriodicArray(")
    Base.showarg(io, parent(arr), false)
    print(io, ')')
    # toplevel && print(io, " with eltype ", eltype(arr))
end



Base.empty(a::PeriodicVector{T}, ::Type{U}=T) where {T, U} = PeriodicVector{U}(U[], a.map)
Base.empty!(a::PeriodicVector) = (empty!(parent(a)); a)
Base.push!(a::PeriodicVector, x...) = (push!(parent(a), x...); a)
Base.append!(a::PeriodicVector, items) = (append!(parent(a), items); a)
Base.resize!(a::PeriodicVector, nl::Integer) = (resize!(parent(a), nl); a)
Base.pop!(a::PeriodicVector) = pop!(parent(a))
Base.sizehint!(a::PeriodicVector, sz::Integer) = (sizehint!(parent(a), sz); a)

function Base.deleteat!(a::PeriodicVector, i::Integer)
    deleteat!(parent(a), mod(i, eachindex(IndexLinear(), parent(a))))
    return a
end

function Base.deleteat!(a::PeriodicVector, inds)
    deleteat!(parent(a), sort!(unique(map(i -> mod(i, eachindex(IndexLinear(), parent(a))), inds))))
    return a
end

function Base.insert!(a::PeriodicVector, i::Integer, item)
    insert!(parent(a), mod(i, eachindex(IndexLinear(), parent(a))), item)
    return a
end

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

        @inline function map_new(x::T, shift::Vararg{Int, N})
            # shifts passed to this map refer to super-cell shifts; amplify
            # by `outer` to convert them to original unit-cell shifts.
            amplified = ntuple(i -> shift[i] * outer[i], N)
            return map(x, amplified...)
        end

        return PeriodicArray(A_tiled, map_new)
    end

    return PeriodicArray(A_new, map)
end

function Base.reverse(arr::PeriodicArray{T, N, A, F}) where {T, N, A, F}
    base = reverse(parent(arr))

    @inline function map_rev(x::T, shifts::Vararg{Int, N})
        neg = ntuple(i -> -shifts[i], N)
        return arr.map(x, neg...)
    end

    return PeriodicArray(base, map_rev)
end

function Base.reverse(arr::PeriodicArray{T, N, A, F}; dims::Integer...) where {T, N, A, F}
    base = reverse(parent(arr), dims...)
    dimsset = Set(dims)

    @inline function map_rev(x::T, shifts::Vararg{Int, N})
        adj = ntuple(i -> (i in dimsset) ? -shifts[i] : shifts[i], N)
        return arr.map(x, adj...)
    end

    return PeriodicArray(base, map_rev)
end

end
