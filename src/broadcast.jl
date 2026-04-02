struct PeriodicArrayStyle{N} <: Broadcast.AbstractArrayStyle{N} end
PeriodicArrayStyle{N}(::Val{M}) where {N, M} = PeriodicArrayStyle{M}()

Broadcast.BroadcastStyle(::Type{<:PeriodicArray{T, N}}) where {T, N} = PeriodicArrayStyle{N}()
Broadcast.BroadcastStyle(::PeriodicArrayStyle{M}, ::PeriodicArrayStyle{N}) where {M, N} = PeriodicArrayStyle{max(M, N)}()
Broadcast.BroadcastStyle(::PeriodicArrayStyle{M}, ::Broadcast.DefaultArrayStyle{N}) where {M, N} = PeriodicArrayStyle{max(M, N)}()
Broadcast.BroadcastStyle(::Broadcast.DefaultArrayStyle{N}, ::PeriodicArrayStyle{M}) where {N, M} = PeriodicArrayStyle{max(N, M)}()

_find_pa(bc::Broadcast.Broadcasted) = _find_pa(bc.args...)
_find_pa(a::Broadcast.Extruded, rest...) = _find_pa(a.x, rest...)
_find_pa() = nothing
_find_pa(a::PeriodicArray, rest...) = a
_find_pa(a::Broadcast.Broadcasted, rest...) =
let r = _find_pa(a)
    r !== nothing ? r : _find_pa(rest...)
end
_find_pa(::Any, rest...) = _find_pa(rest...)

@inline function Base.similar(
        bc::Broadcast.Broadcasted{PeriodicArrayStyle{N}}, ::Type{ElType}
    ) where {N, ElType}
    pa = _find_pa(bc)
    return PeriodicArray(similar(Array{ElType, N}, axes(bc)), pa.fmap, pa.imap)
end
