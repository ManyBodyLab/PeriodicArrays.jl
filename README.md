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
A `PeriodicArray{T,N,A,F,G}` is an `AbstractArray{T,N}` backed by a data array of type `A<:AbstractArray{T,N}`, a forward map `fmap` of type `F`, and an inverse map `imap` of type `G`.
The maps define how data at out-of-bounds indices is translated to and from valid indices in the data array.

`fmap` and `imap` can be any callable objects (e.g. functions or structs) that define
```julia
fmap(x, shift::Vararg{Int,N})
```
where `x` is an element of the array and `shift` encodes the unit cell in which we index.

`PeriodicArray` accepts the maps as `PeriodicArray(data, fmap)` or
`PeriodicArray(data, fmap, imap)`.
If neither map is provided, both default to the identity and the array behaves like a `CircularArray`.

**Constraints on `fmap`** (not checked at construction time):
- The output type of `fmap` must be the same as the element type of the data array.

**Constraints on `imap`** (the inverse map used by `setindex!`):
- `imap` must satisfy `imap(fmap(x, shift...), shift...) == x` for all valid `x` and
  `shift`, so that round-tripping a value through `getindex`/`setindex!` is lossless.
- When `imap` is omitted, it defaults to `(x, shifts...) -> fmap(x, -shifts...)`.
  This default is correct whenever `fmap` is self-inverse under shift negation, i.e.
  `fmap(fmap(x, s...), -s...) == x`.
- If `fmap` does **not** satisfy the self-inverse property, supply a custom `imap`.
  If mutation through out-of-bounds indices should be explicitly forbidden, pass an
  `imap` that throws:
  ```julia
  imap_error(x, shift...) = error("mutation through out-of-bounds indices is not supported")
  a = PeriodicArray(data, fmap, imap_error)
  ```

This package is compatible with [`OffsetArrays.jl`](https://github.com/JuliaArrays/OffsetArrays.jl).

## Installation

The package is registered in the Julia general registry. It can be installed trough the package manager with the following command:

```julia-repl
pkg> add PeriodicArrays
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

## Known Limitations

**Iterated indexing for mutation does not work** when the map is non-trivial.
For a `PeriodicArray` whose elements are themselves mutable (e.g. an array of matrices), writing

```julia
x[out_of_bounds_index][i, j] = value
```

silently does nothing to `x`. The reason is that `x[out_of_bounds_index]` applies the map and returns a *new, transformed copy* of the element; the subsequent assignment mutates only that temporary object, not the underlying data.

For in-bounds indices the element is returned by reference and mutation works as expected.

**Recommended workaround — `mapped_ref`:**

```julia
ref = mapped_ref(x, out_of_bounds_index)
ref[i, j] = value   # applies imap and writes back into parent(x)
```

`mapped_ref` returns a `MappedRef`: a lazy wrapper that applies the forward map on reads
and the inverse map on writes, so no temporary copy is created and the mutation propagates
correctly into the underlying data.

**Alternative workarounds** (lower-level):

Operate directly on the underlying data (bypasses the map entirely):

```julia
parent(x)[mod_index][i, j] = value
```

Or set the whole element at once (goes through `setindex!` on `x` and applies `imap`):

```julia
tmp = copy(x[out_of_bounds_index])
tmp[i, j] = value
x[out_of_bounds_index] = tmp
```

## License

PeriodicArrays.jl is licensed under the [MIT License](LICENSE). By using or interacting with this software in any way, you agree to the license of this software.
