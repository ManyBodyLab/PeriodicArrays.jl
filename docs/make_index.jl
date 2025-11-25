using Literate: Literate
using PeriodicArrays

Literate.markdown(
    joinpath(pkgdir(PeriodicArrays), "examples", "README.jl"),
    joinpath(pkgdir(PeriodicArrays), "docs", "src");
    flavor = Literate.DocumenterFlavor(),
    name = "index",
)