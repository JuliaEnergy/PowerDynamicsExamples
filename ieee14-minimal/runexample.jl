using PowerDynamics: read_powergrid, Json, find_operationpoint, Perturbation, Inc, LineFault, simulate
using Plots: savefig
include("plotting.jl")

powergrid = read_powergrid("ieee-14-minimal.json", Json)

operationpoint = find_operationpoint(powergrid)

# simulating a frequency perturbation at node 1
solution1 = simulate(Perturbation(1, :ω, Inc(0.2)), powergrid, operationpoint, timespan = (0.0,10.))
plot1 = create_plot(solution1)
savefig(plot1,"ieee14-minimal-omega_perturbation.pdf")

# simulating a tripped line between node 1 and 5
solution2 = simulate(LineFault(from=1,to=5), powergrid, operationpoint, timespan = (0.0,10.0))
plot2 = create_plot(solution2)
savefig(plot2, "ieee14-minimal-line-fault.pdf")
