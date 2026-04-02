_circshift_amounts(::Val{N}, s::Integer) where {N} = ntuple(d -> d == 1 ? Int(s) : 0, N)
_circshift_amounts(::Val{N}, s) where {N} = ntuple(d -> d <= length(s) ? Int(s[d]) : 0, N)

function _circshift_pa!(
        dest::PeriodicArray{T, N}, src::PeriodicArray{T, N}, shifts
    ) where {T, N}
    s = _circshift_amounts(Val(N), shifts)
    src_data = parent(src)
    dest_data = parent(dest)
    for k in CartesianIndices(dest_data)
        i = ntuple(d -> k[d] - s[d], N)
        i_base, i_shift = cell_position(src_data, i...)
        v = src_data[i_base...]
        dest_data[k] = src.fmap(v, i_shift...)
    end
    return dest
end

# circshift: multiple signatures to disambiguate from Base methods
Base.circshift(arr::PeriodicArray{T, N}, shifts::NTuple{M, Integer}) where {T, N, M} =
    _circshift_pa!(similar(arr), arr, shifts)
Base.circshift(arr::PeriodicArray{T, N}, shift::Real) where {T, N} =
    _circshift_pa!(similar(arr), arr, shift)
Base.circshift(arr::PeriodicArray{T, N}, shifts::AbstractVector{<:Integer}) where {T, N} =
    _circshift_pa!(similar(arr), arr, shifts)

# circshift! 2-arg (in-place)
function Base.circshift!(arr::PeriodicArray{T, N}, shifts) where {T, N}
    src = PeriodicArray(copy(parent(arr)), arr.fmap, arr.imap)
    return _circshift_pa!(arr, src, shifts)
end
# disambiguate with Base.circshift!(::AbstractVector, ::Integer)
Base.circshift!(arr::PeriodicVector, shift::Integer) = circshift!(arr, (shift,))

# circshift! 3-arg: specific shift types to disambiguate from Base methods
Base.circshift!(
    dest::PeriodicArray{T, N}, src::PeriodicArray{T, N}, shifts::NTuple{M, Integer}
) where {T, N, M} = _circshift_pa!(dest, src, shifts)
Base.circshift!(
    dest::PeriodicArray{T, N}, src::PeriodicArray{T, N}, ::Tuple{}
) where {T, N} = _circshift_pa!(dest, src, ())
Base.circshift!(
    dest::PeriodicArray{T, N}, src::PeriodicArray{T, N}, shifts::AbstractVector{<:Integer}
) where {T, N} = _circshift_pa!(dest, src, shifts)
