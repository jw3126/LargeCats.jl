using LargeCats
using Documenter

makedocs(;
    modules=[LargeCats],
    authors="Jan Weidner <jw3126@gmail.com> and contributors",
    repo="https://github.com/jw3126/LargeCats.jl/blob/{commit}{path}#L{line}",
    sitename="LargeCats.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jw3126.github.io/LargeCats.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jw3126/LargeCats.jl",
)
