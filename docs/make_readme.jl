using Literate: Literate
using PeriodicArrays

Literate.markdown(
    joinpath(pkgdir(PeriodicArrays), "examples", "README.jl"),
    joinpath(pkgdir(PeriodicArrays));
    flavor = Literate.CommonMarkFlavor(),
    name = "README",
)