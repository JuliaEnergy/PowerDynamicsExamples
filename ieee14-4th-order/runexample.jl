using PowerDynamics: SlackAlgebraic, FourthOrderEq, PQAlgebraic, StaticLine, PowerGrid, Inc, find_operationpoint, ChangeInitialConditions, LineFailure, simulate
using OrderedCollections: OrderedDict
using Plots: savefig

include("plotting.jl")

nodes=OrderedDict(
    "bus1"=> FourthOrderEq(T_d_dash=7.4, D=2, X_d=0.8979, X_q=0.646, Ω=50, X_d_dash=0.2995, T_q_dash=0.1, X_q_dash=0.646, P=2.32, H=5.148, E_f=1),
    "bus2"=> SlackAlgebraic(U=1),
    "bus3"=> FourthOrderEq(T_d_dash=6.1, D=2, X_d=1.05, X_q=0.98, Ω=50, X_d_dash=0.185, T_q_dash=0.4, X_q_dash=0.36, P=-0.942, H=6.54, E_f= 1),
    "bus4"=> PQAlgebraic(P=-0.478, Q=-0.0),
    "bus5"=> PQAlgebraic(P=-0.076, Q=-0.016),
    "bus6"=> FourthOrderEq(T_d_dash=4.75, D=2, X_d=1.25, X_q=1.22, Ω=50, X_d_dash=0.232, T_q_dash=1.6, X_q_dash=0.715, P=-0.122, H=5.06, E_f= 1),
    "bus7"=> PQAlgebraic(P=-0.0, Q=-0.0),
    "bus8"=> FourthOrderEq(T_d_dash=4.75, D=2, X_d=1.25, X_q=1.22, Ω=50, X_d_dash=0.232, T_q_dash=1.6, X_q_dash=0.715, P=0.0, H=5.06, E_f= 1),
    "bus9"=> PQAlgebraic(P=-0.295, Q=-0.166),
    "bus10"=> PQAlgebraic(P=-0.09, Q=-0.058),
    "bus11"=> PQAlgebraic(P=-0.035, Q=-0.018),
    "bus12"=> PQAlgebraic(P=-0.061, Q=-0.016),
    "bus13"=> PQAlgebraic(P=-0.135, Q=-0.058),
    "bus14"=> PQAlgebraic(P=-0.149, Q=-0.05));

lines=OrderedDict(
    "line1"=> StaticLine(from= "bus1", to = "bus2",Y=4.999131600798035-1im*15.263086523179553),
    "line2"=> StaticLine(from= "bus1", to = "bus5",Y=1.025897454970189-1im*4.234983682334831),
    "line3"=> StaticLine(from= "bus2", to = "bus3",Y=1.1350191923073958-1im*4.781863151757718),
    "line4"=> StaticLine(from= "bus2", to = "bus4",Y=1.686033150614943-1im*5.115838325872083),
    "line5"=> StaticLine(from= "bus2", to = "bus5",Y=1.7011396670944048-1im*5.193927397969713),
    "line6"=> StaticLine(from= "bus3", to = "bus4",Y=1.9859757099255606-1im*5.0688169775939205),
    "line7"=> StaticLine(from= "bus4", to = "bus5",Y=6.840980661495672-1im*21.578553981691588),
    "line8"=> StaticLine(from= "bus4", to = "bus7",Y=0.0-1im*4.781943381790359),
    "line9"=> StaticLine(from= "bus4", to = "bus9",Y=0.0-1im*1.7979790715236075),
    "line10"=> StaticLine(from= "bus5", to = "bus6",Y=0.0-1im*3.967939052456154),
    "line11"=> StaticLine(from= "bus6", to = "bus11",Y=1.9550285631772604-1im*4.0940743442404415),
    "line12"=> StaticLine(from= "bus6", to = "bus12",Y=1.525967440450974-1im*3.1759639650294003),
    "line13"=> StaticLine(from= "bus6", to = "bus13",Y=3.0989274038379877-1im*6.102755448193116),
    "line14"=> StaticLine(from= "bus7", to = "bus8",Y=0.0-1im*5.676979846721544),
    "line15"=> StaticLine(from= "bus7", to = "bus9",Y=0.0-1im*9.09008271975275),
    "line16"=> StaticLine(from= "bus9", to = "bus10",Y=3.902049552447428-1im*10.365394127060915),
    "line17"=> StaticLine(from= "bus9", to = "bus14",Y=1.4240054870199312-1im*3.0290504569306034),
    "line18"=> StaticLine(from= "bus10", to = "bus11",Y=1.8808847537003996-1im*4.402943749460521),
    "line19"=> StaticLine(from= "bus12", to = "bus13",Y=2.4890245868219187-1im*2.251974626172212),
    "line20"=> StaticLine(from= "bus13", to = "bus14",Y=1.1369941578063267-1im*2.314963475105352))


powergrid = PowerGrid(nodes, lines) 

operationpoint = find_operationpoint(powergrid)

timespan= (0.0,5.)
# simulating a frequency perturbation at node 1
solution1 = simulate(ChangeInitialConditions("bus1", :ω, Inc(0.2)), powergrid, operationpoint, timespan)
plot1 = create_plot(solution1)
savefig(plot1, "ieee14-4th-order-frequency-perturbation.pdf")
display(plot1)

# simulating a tripped line between node 1 and 5
solution2 = simulate(LineFailure(line_name ="line2", tspan_fault=(0,5)), powergrid, operationpoint, timespan)
plot2 = create_plot(solution2)
savefig(plot2, "ieee14-4th-order-line-tripping.pdf")
display(plot2)


using Weave: convert_doc 
convert_doc("runexample.jl", "runexample.ipynb")