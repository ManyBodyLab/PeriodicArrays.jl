"""
Arrays with fixed size and arbitrary boundary conditions.
"""
module PeriodicArrays

export PeriodicArray, PeriodicVector, PeriodicMatrix

include("types.jl")
include("indexing.jl")
include("broadcast.jl")
include("vector_interface.jl")
include("repeat.jl")
include("circshift.jl")
include("reverse.jl")
include("mapped_ref.jl")

end
