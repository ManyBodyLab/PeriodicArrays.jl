# PeriodicArrays.jl

| **Documentation** | **Downloads** |
|:-----------------:|:-------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Downloads][downloads-img]][downloads-url]

| **Build Status** | **Coverage** | **Style Guide** | **Quality assurance** |
|:----------------:|:------------:|:---------------:|:---------------------:|
| [![CI][ci-img]][ci-url] | [![Codecov][codecov-img]][codecov-url] | [![code style: runic][codestyle-img]][codestyle-url] | [![Aqua QA][aqua-img]][aqua-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://manybodylab.github.io/PeriodicArrays.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://manybodylab.github.io/PeriodicArrays.jl/dev

[downloads-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FPeriodicArrays&query=total_requests&label=Downloads
[downloads-url]: http://juliapkgstats.com/pkg/PeriodicArrays

[ci-img]: https://github.com/ManyBodyLab/PeriodicArrays.jl/actions/workflows/Tests.yml/badge.svg
[ci-url]: https://github.com/ManyBodyLab/PeriodicArrays.jl/actions/workflows/Tests.yml

[codecov-img]: https://codecov.io/gh/ManyBodyLab/PeriodicArrays.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/ManyBodyLab/PeriodicArrays.jl

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

[codestyle-img]: https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black
[codestyle-url]: https://github.com/fredrikekre/Runic.jl

`PeriodicArrays.jl` adds the `PeriodicArray` type which can be backed by any `AbstractArray`. The idea of this package is based on [`CircularArrays.jl`](https://github.com/Vexatos/CircularArrays.jl) and extends its functionality to support user-defined translation rules for periodic indexing. 
A `PeriodicArray{T,N,A,F}` is an `AbstractArray{T,N}` backed by a data array of type `A<:AbstractArray{T,N}` and a map `f` of type `F`. 
The map defines how data in out-of-bounds indices is translated to valid indices in the data array.

`f` can be any callable object (e.g. a function or a struct), which defines 
```julia 
f(x, shift::Vararg{Int,N})
```
where `x` is an element of the array and shift encodes the unit cell, in which we index.
`f` has to satisfy the following properties, which are not checked at construction time:
- The output type of `f` has to be the same as the element type of the data array.
- `f` is invertible with inverse `f(x, -shift...)`, i.e. it satisfies `f(f(x, shift...), -shift...) == x`.

If `f` is not provided, the identity map is used and the `PeriodicArray` behaves like a `CircularArray`.

This package is compatible with [`OffsetArrays.jl`](https://github.com/JuliaArrays/OffsetArrays.jl).

## Installation

The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

```julia-repl
pkg> add git@github.com:ManyBodyLab/PeriodicArrays.jl.git
```

## Code Samples

```julia
julia> using PeriodicArrays
julia> a = PeriodicVector([1,2,3])
julia> a[0:4]
5-element PeriodicVector(::Vector{Int64}):
 3
 1
 2
 3
 1
julia> f(x, shift...) = x + 10 * sum(shift)
julia> a2 = PeriodicArray([1,2,3], f);
julia> a2[0:4]
5-element PeriodicVector(::Vector{Int64}):
 -7
  1
  2
  3
 11
julia> struct MyTranslator end;
julia> (f::MyTranslator)(x, shift) = x - shift;
julia> a3 = PeriodicArray([1,2,3], MyTranslator());
julia> a3[0:4]
5-element PeriodicVector(::Vector{Int64}):
 4
 1
 2
 3
 0
julia> using OffsetArrays
julia> data = reshape(1:9, 3, 3);
julia> i = OffsetArray(1:5, -2:2);
julia> a4 = PeriodicMatrix(data, f);
julia> a4[i,i]
5×5 PeriodicArray(OffsetArray(::Matrix{Int64}, -2:2, -2:2)) with indices -2:2×-2:2:
  1   4   7  11  14
  2   5   8  12  15
  3   6   9  13  16
 11  14  17  21  24
 12  15  18  22  25
```

## License

PeriodicArrays.jl is licensed under the [MIT License](LICENSE). By using or interacting with this software in any way, you agree to the license of this software.
