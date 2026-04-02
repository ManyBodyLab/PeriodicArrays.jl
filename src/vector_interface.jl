Base.empty(a::PeriodicVector{T}, ::Type{U} = T) where {T, U} = PeriodicVector{U}(U[], a.fmap, a.imap)
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
