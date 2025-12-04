# # PeriodicArrays.jl

# `PeriodicArrays.jl` adds the `PeriodicArray` type which can be backed by any `AbstractArray`. The idea of this package is based on [`CircularArrays.jl`](https://github.com/Vexatos/CircularArrays.jl) and extends its functionality to support user-defined translation rules for periodic indexing. 
# A `PeriodicArray{T,N,A,F}` is an `AbstractArray{T,N}` backed by a data array of type `A<:AbstractArray{T,N}` and a map `f` of type `F`. 
# The map defines how data in out-of-bounds indices is translated to valid indices in the data array.

# `f` can be any callable object (e.g. a function or a struct), which defines 
# ```julia 
# f(x, shift::Vararg{Int,N})
# ```
# where `x` is an element of the array and shift encodes the unit cell, in which we index.
# `f` has to satisfy the following properties, which are not checked at construction time:
# - The output type of `f` has to be the same as the element type of the data array.
# - `f` is invertible with inverse `f(x, -shift...)`, i.e. it satisfies `f(f(x, shift...), -shift...) == x`.

# If `f` is not provided, the identity map is used and the `PeriodicArray` behaves like a `CircularArray`.

# This package is compatible with [`OffsetArrays.jl`](https://github.com/JuliaArrays/OffsetArrays.jl).

# ## Installation

# The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

# ```julia-repl
# pkg> add git@github.com:ManyBodyLab/PeriodicArrays.jl.git
# ```

# ## Code Samples

# ```julia
# julia> using PeriodicArrays
# julia> a = PeriodicVector([1,2,3])
# julia> a[0:4]
# 5-element PeriodicVector(::Vector{Int64}):
#  3
#  1
#  2
#  3
#  1
# julia> f(x, shift...) = x + 10 * sum(shift)
# julia> a2 = PeriodicArray([1,2,3], f);
# julia> a2[0:4]
# 5-element PeriodicVector(::Vector{Int64}):
#  -7
#   1
#   2
#   3
#  11
# julia> struct MyTranslator end;
# julia> (f::MyTranslator)(x, shift) = x - shift;
# julia> a3 = PeriodicArray([1,2,3], MyTranslator());
# julia> a3[0:4]
# 5-element PeriodicVector(::Vector{Int64}):
#  4
#  1
#  2
#  3
#  0
# julia> using OffsetArrays
# julia> data = reshape(1:9, 3, 3);
# julia> i = OffsetArray(1:5, -2:2);
# julia> a4 = PeriodicMatrix(data, f);
# julia> a4[i,i]
# 5×5 PeriodicArray(OffsetArray(::Matrix{Int64}, -2:2, -2:2)) with indices -2:2×-2:2:
#   1   4   7  11  14
#   2   5   8  12  15
#   3   6   9  13  16
#  11  14  17  21  24
#  12  15  18  22  25
# ```

# ## License

# PeriodicArrays.jl is licensed under the MIT License. By using or interacting with this software in any way, you agree to the license of this software.
