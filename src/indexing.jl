function cell_position(arr::AbstractArray{T, N}, I::Vararg{Integer, N}) where {T, N}
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

# Special case for trivial fmap (identical to CelledArrays.jl)
@inline function Base.getindex(
        arr::PeriodicArray{T, N, A, _identity_map_type, _identity_map_type}, i::Int
    ) where {A <: AbstractArray{T, N}} where {T, N}
    return @inbounds getindex(parent(arr), mod(i, eachindex(IndexLinear(), parent(arr))))
end
@inline function Base.setindex!(
        arr::PeriodicArray{T, N, A, _identity_map_type, _identity_map_type}, v, i::Int
    ) where {A <: AbstractArray{T, N}} where {T, N}
    return @inbounds setindex!(parent(arr), v, mod(i, eachindex(IndexLinear(), parent(arr))))
end

@inline function Base.getindex(
        arr::PeriodicArray{T, N, A, F, G}, I::Vararg{Int, N}
    ) where {T, N, A, F, G}
    i_base, i_shift = cell_position(arr, I...)

    @inbounds v = getindex(parent(arr), i_base...)
    all(iszero, i_shift) && return v
    return arr.fmap(v, i_shift...)
end
@inline function Base.setindex!(
        arr::PeriodicArray{T, N, A, F, G}, v, I::Vararg{Int, N}
    ) where {T, N, A, F, G}
    i_base, i_shift = cell_position(arr, I...)

    all(iszero, i_shift) && return @inbounds setindex!(parent(arr), v, i_base...)
    return @inbounds setindex!(parent(arr), arr.imap(v, i_shift...), i_base...)
end

# Linear indexing is not well-defined outside of the first unit-cell
function Base.getindex(
        arr::PeriodicArray{T, N, A, F, G}, i::Int
    ) where {T, N, A <: AbstractArray{T, N}, F, G}
    if Base.checkbounds(Bool, parent(arr), i)
        return @inbounds getindex(parent(arr), i)
    end
    throw(BoundsError(arr, i))
end
function Base.setindex!(
        arr::PeriodicArray{T, N, A, F, G}, v, i::Int
    ) where {T, N, A <: AbstractArray{T, N}, F, G}
    if Base.checkbounds(Bool, parent(arr), i)
        return @inbounds setindex!(parent(arr), v, i)
    end
    throw(BoundsError(arr, i))
end

@inline function Base.checkbounds(arr::PeriodicArray, I...)
    J = Base.to_indices(arr, I)
    length(J) == 1 || length(J) >= ndims(arr) || throw(BoundsError(arr, I))
    return nothing
end
