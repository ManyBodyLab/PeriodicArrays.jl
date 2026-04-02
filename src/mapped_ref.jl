"""
    MappedRef{E, N, T, S, F, G} <: AbstractArray{E, N}

A mutable view over an element of a `PeriodicArray` that applies forward/inverse maps
lazily on element access and mutation.

- `ref[I...]` returns `fmap(parent_element[I...], shift...)`.
- `ref[I...] = val` stores `imap(val, shift...)` back into `parent_element[I...]`,
  propagating the mutation to the underlying `PeriodicArray` without any copying.

Obtain a `MappedRef` via [`mapped_ref`](@ref) rather than constructing it directly.
"""
struct MappedRef{E, N, T <: AbstractArray{E, N}, S <: Tuple, F, G} <: AbstractArray{E, N}
    ref::T   # direct reference into parent(arr) — NOT a copy
    shift::S # original periodic shift (same sign convention as PeriodicArray.map)
    fmap::F  # forward map: (scalar, shift...) -> mapped_scalar
    imap::G  # inverse map: (val, shift...) -> original_val
end

Base.size(r::MappedRef) = size(r.ref)
Base.IndexStyle(::Type{<:MappedRef}) = IndexCartesian()
Base.parent(r::MappedRef) = r.ref

@inline function Base.getindex(r::MappedRef{E, N}, I::Vararg{Int, N}) where {E, N}
    return r.fmap(@inbounds(r.ref[I...]), r.shift...)
end

@inline function Base.setindex!(r::MappedRef{E, N}, val, I::Vararg{Int, N}) where {E, N}
    @inbounds r.ref[I...] = r.imap(val, r.shift...)
    return val
end

"""
    mapped_ref(arr::PeriodicArray{T}, I...) -> MappedRef or element reference

Return a lazy mutable wrapper for the element at periodic index `I...` in `arr`.

For in-bounds indices (zero shift) the raw element is returned directly, so normal
Julia mutation semantics apply. For out-of-bounds (wrapped) indices a `MappedRef` is
returned: reading through it applies `arr.map` element-wise; writing through it applies
`arr.imap` element-wise and stores the result back into the underlying data.

# Example
```julia
x = PeriodicVector([zeros(3, 3), zeros(3, 3)], (v, s) -> v .+ s)
# imap defaults to NegatedShiftMap: (v, s) -> v .- s

ref = mapped_ref(x, 3)   # wraps parent(x)[1] with shift = (1,)
ref[1, 1] = 100.0         # → parent(x)[1][1, 1] = imap(100, 1) = 99
x[1][1, 1]                # → 99.0
x[3][1, 1]                # → 100.0  (standard getindex still correct)
```
"""
function mapped_ref(arr::PeriodicArray{T, N}, I::Vararg{Int, N}) where {T <: AbstractArray, N}
    i_base, i_shift = cell_position(arr, I...)
    ref = @inbounds parent(arr)[i_base...]
    all(iszero, i_shift) && return ref
    return MappedRef(ref, i_shift, arr.map, arr.imap)
end
