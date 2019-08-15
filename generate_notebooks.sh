julia --check-bounds=yes --color=yes -e "using Pkg; Pkg.activate(\"./notebooks\"); using Literate;
Literate.notebook(\"ieee14-4th-order/runexample.jl\",\"ieee14-4th-order\",execute=false)
Literate.notebook(\"ieee14-minimal/runexample.jl\",\"ieee14-minimal\",execute=false)
"
