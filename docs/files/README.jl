# <img src="./docs/src/assets/logo_readme.svg" width="150">

# # PeriodicArrays.jl

# | **Documentation** | **Downloads** |
# |:-----------------:|:-------------:|
# | [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Downloads][downloads-img]][downloads-url]

# <!-- | **Documentation** | **Digital Object Identifier** | **Citation** | **Downloads** |
# |:-----------------:|:-----------------------------:|:------------:|:-------------:|
# | [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![DOI][doi-img]][doi-url] | | [![Downloads][downloads-img]][downloads-url] -->

# | **Build Status** | **PkgEval** | **Coverage** | **Style Guide** | **Quality assurance** |
# |:----------------:|:-----------:|:------------:|:---------------:|:---------------------:|
# | [![CI][ci-img]][ci-url] | [![PkgEval][pkgeval-img]][pkgeval-url] | [![Codecov][codecov-img]][codecov-url] | [![code style: runic][codestyle-img]][codestyle-url] | [![Aqua QA][aqua-img]][aqua-url] |

# [docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
# [docs-stable-url]: https://manybodylab.github.io/PeriodicArrays.jl/stable

# [docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
# [docs-dev-url]: https://manybodylab.github.io/PeriodicArrays.jl/dev

# [doi-img]: https://zenodo.org/badge/DOI/
# [doi-url]: https://doi.org/

# [downloads-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FPeriodicArrays&query=total_requests&label=Downloads
# [downloads-url]: http://juliapkgstats.com/pkg/PeriodicArrays

# [ci-img]: https://github.com/ManyBodyLab/PeriodicArrays.jl/actions/workflows/Tests.yml/badge.svg
# [ci-url]: https://github.com/ManyBodyLab/PeriodicArrays.jl/actions/workflows/Tests.yml

# [pkgeval-img]: https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/M/PeriodicArrays.svg
# [pkgeval-url]: https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/M/PeriodicArrays.html

# [codecov-img]: https://codecov.io/gh/ManyBodyLab/PeriodicArrays.jl/branch/main/graph/badge.svg
# [codecov-url]: https://codecov.io/gh/ManyBodyLab/PeriodicArrays.jl

# [aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
# [aqua-url]: https://github.com/JuliaTesting/Aqua.jl

# [codestyle-img]: https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black
# [codestyle-url]: https://github.com/fredrikekre/Runic.jl


# ## Installation

# The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

# ```julia-repl
# pkg> add git@github.com:ManyBodyLab/PeriodicArrays.jl.git
# ```

# <!-- ## Citation

# See "Cite this repository" to the right or [`CITATION.cff`](CITATION.cff) for the relevant reference(s). -->

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

# ---

# *This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
