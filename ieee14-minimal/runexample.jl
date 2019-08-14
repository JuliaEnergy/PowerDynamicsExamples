using PowerDynamics: read_powergrid, Json, find_operationpoint, Perturbation, LineFault, simulate

include("plotting.jl")

powergrid = read_powergrid("ieee-14-minimal.json", Json)

operationpoint = find_operationpoint(powergrid)

result = simulate(Perturbation(1, :ω, Inc(0.2)), powergrid, operationpoint, timespan = (0.0,10.))
pl = plot_res(result, powergrid)
#savefig(pl,"ieee14-minimal-omega_perturbation.pdf")

result = simulate(LineFault(from=1,to=5), powergrid, operationpoint, timespan = (0.0,10.0))
pl= plot_res(result, powergrid)
#savefig(pl, "ieee14-minimal-line-fault.pdf")
