using PowerDynamics: read_powergrid, Json, find_operationpoint, Perturbation, LineFault, simulate

include("plotting.jl")

powergrid = read_powergrid("ieee-14-minimal.json", Json)

operationpoint = find_operationpoint(powergrid)

result = simulate(Perturbation(1, :ω, Inc(0.2)), powergrid, operationpoint, timespan = (0.0,0.3))
plot_res(result, powergrid)

result = simulate(LineFault(from=1,to=5), powergrid, operationpoint, timespan = (0.0,1.0))
plot_res(result, powergrid)
