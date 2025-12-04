using PeriodicArrays
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
    PeriodicArrays, :DocTestSetup, :(using PeriodicArrays); recursive = true
)

include("make_index.jl")

makedocs(;
    modules = [PeriodicArrays],
    authors = "Andreas Feuerpfeil <development@manybodylab.com>",
    sitename = "PeriodicArrays.jl",
    format = Documenter.HTML(;
        canonical = "https://manybodylab.github.io/PeriodicArrays.jl",
        edit_link = "main",
        assets = [#"assets/logo.png", 
        "assets/extras.css"],
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
    repo = "github.com/ManyBodyLab/PeriodicArrays.jl", devbranch = "main", push_preview = true
)
