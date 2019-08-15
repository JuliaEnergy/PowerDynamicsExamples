julia --check-bounds=yes --color=yes -e "using Pkg; Pkg.activate(\"./notebooks\"); using Literate; Literate.notebook(\"runexample.jl\",\".\",execute=false)"
