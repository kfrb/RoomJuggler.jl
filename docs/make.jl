using RoomJuggler
using Documenter

DocMeta.setdocmeta!(RoomJuggler, :DocTestSetup, :(using RoomJuggler); recursive=true)

makedocs(;
    modules=[RoomJuggler],
    authors="Kai Partmann",
    repo="https://github.com/kaipartmann/RoomJuggler.jl/blob/{commit}{path}#{line}",
    sitename="RoomJuggler.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kaipartmann.github.io/RoomJuggler.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/kaipartmann/RoomJuggler.jl",
    devbranch="main",
)
