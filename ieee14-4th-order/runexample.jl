using PowerDynamics: read_powergrid, Json, SlackAlgebraic, FourthOrderEq, PQAlgebraic, StaticLine, PowerGrid, Inc, find_operationpoint, Perturbation, LineFault, simulate

include("plotting.jl")

powergrid = read_powergrid("ieee14-4th-order.json", Json)
operationpoint = find_operationpoint(powergrid)

# simulating a frequency perturbation at node 1
solution1 = simulate(Perturbation(1, :ω, Inc(0.2)), powergrid, operationpoint, timespan = (0.0,0.3))
plot1 = create_plot(solution)
savefig(plot1, "ieee14-4th-order-frequency-perturbation.pdf")
display(plot1)

# simulating a tripped line between node 1 and 5
solution2 = simulate(LineFault(from=1,to=5), powergrid, operationpoint, timespan = (0.0,100.0))
plot2 = create_plot(solution2)
savefig(plot2, "ieee14-4th-order-line-tripping.pdf")
display(plot2)
