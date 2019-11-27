using PowerDynamics

include("openloopdyn.jl")
include("ieee14-4th-order/plotting.jl")

showdefinition(stdout, OpenLoopSwingEq)
# OpenLoopSwingEq(H=1., D=0.1, Ω=50.)

nodes = [
        #FourthOrderEq(H=5.148, P=2.32, D=4., Ω=50., E_f=2.32, T_d_dash=7.4 ,T_q_dash=0.1 ,X_q_dash=0.646 ,X_d_dash=0.2995,X_d=0.8979, X_q=0.646),
        OpenLoopSwingEq(H=1., D=0.1, Ω=50.),
        SlackAlgebraic(U=1.)
        ]

lines =[StaticLine(from=1, to=2, Y=1. + 5. * im)]

pg = PowerGrid(nodes, lines)

systemsize(pg)

op = find_operationpoint(pg, randn(systemsize(pg)))

p = PowerPerturbation(;node_number=1,fraction=1.,tspan_fault=(0.5, 0.6))
#p = Perturbation(1, :ω, Inc(0.2))

solution1 = simulate(p, pg, op, (0.0,10.))

plot1 = create_plot(solution1)
