begin
    ENV["PLOTS_USE_ATOM_PLOTPANE"] = "false"
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
    cd(@__DIR__)
end

begin
    using CSV
    using DataFrames
    using PowerDynamics
    using PowerDynBase: AbstractNodeParameters, AbstractNodeDynamics
    using LaTeXStrings
    using Plots
    # Plots.scalefontsizes(0.8)
    using SparseArrays
    import PowerDynSolve
end

begin
    num_nodes=2
    println("creating minimal two node example of 4th-order model with one generator and one slack bus")
    node_list = Array{AbstractNodeParameters,1}()
    append!(node_list, [SwingEqLVS(
        H=0.1 ,
        P=1,
        D=0.1,
        Ω=50,
        Γ= 2,
        V=1
    )])
    append!(node_list, [SwingEqLVS(
        H=0.1 ,
        P=-1,
        D=0.1,
        Ω=50,
        Γ= 2,
        V=1
    )])
end

begin
    admittance = -0.1/(1im*0.2+0.3)#1im*B#/0.2*2 #+ 0.03
    Y = spzeros(Complex, num_nodes, num_nodes)
    Y[1,2] = - admittance
    Y[2 ,1] = - admittance
    Y[1, 1] += admittance # note the +=
    Y[2, 2] += admittance # note the +=# just save it, so line tripping can be implemented easier later
    LY =Y
end

begin
    Y_12 = abs(Y[1,2])
    α = angle(Y[1,2])#-π/2
    #with losses
    #-1 = V_2^2*Y_12*sin(α)+V_2*sin(ϕ_2-α)
    #P_1 = Y_12*sin(α)-V_2*sin(ϕ_2+α)
    #0 = V_2^2*Y_12*cos(α)-V_2*cos(ϕ_2-α)
    #Q_1 = Y_12*cos(α)-V_2*cos(ϕ_2+α)

    #without losses
    #-1 = V_2*sin(ϕ_2)
    #P_1 = -V_2*sin(ϕ_2)
    #0 = V_2^2*Y_12-V_2*cos(ϕ_2)
    #Q_1 = Y_12-V_2*cos(ϕ_2)
end

function f!(F, x)
    F[1] = 1 + x[1]^2*Y_12*sin(α)+x[1]*sin(x[2]-α)
    F[2] = -x[3]+ Y_12*sin(α)-x[1]*sin(x[2]+α)
    F[3] = x[1]^2*Y_12*cos(α)-x[1]*cos(x[2]-α)
    F[4] = -x[4] + Y_12*cos(α)-x[1]*cos(x[2]+α)
end
using NLsolve
nlsolve(f!, [1.,0.,1.,0.])

################################################################
# plotting the network representing the power grid
# check the two below for plotting graphs
# using LightGraphs
# using GraphPlot
# g = Graph(Array(LY).!=0)
# gplot(g)
################################################################

# create network dynamics object
g = GridDynamics(node_list, Y)
# search for fixed point

# find the fixed point = normal operation point
# set inital guess for fixed point search
begin
    x_guess = State(g,ones(SystemSize(g)))
    #x_guess[1,:u]=u
    #x_guess[2,:u]=1
    #x_guess[1,:ω]=0
    #x_guess[1,:θ]=theta
    #x_guess = ones(SystemSize(g))
end

# replace the n-th node with a slack bus
begin
    n=1
    nodes = convert(Vector{AbstractNodeParameters}, parametersof.(Nodes(g)))
    #nodes =node_list
    saved_node = nodes[n]
    @assert isa(saved_node, SwingEqLVS)
    nodes[n] = SlackAlgebraic(U=1)
    #then call the original operationpoint function
    g2 = GridDynamics(nodes,Y)
    start = State(g2, ones(SystemSize(g2)))
    res = operationpoint(start)
    # undo the replace process
    # define a new State res2 with all entries 0
    # set voltage of n-th node in res2 to the value of n-th node in res
    # return res2
    res2 = State(g, ones(SystemSize(g)))
    begin
        # iterate through all nodes except n and overwrite :u and all internal variable values
        res2[1,:u]=res[1,:u]
        res2[2,:u]=res[2,:u]
        res2[1,:ω]=res[2,:ω]
        res2[2,:ω]=res[2,:ω]
    end
    #fp = swing_operationpoint(node_list, 1)
    #fp_old = operationpoint(g,x_guess)
    fp_new = res2
    # SwingEqLVS neu generieren mit P gleich res[1,:p]
    node_list_updated = node_list
    node_list_updated[1]=SwingEqLVS(
        H=0.1 ,
        P=res[1,:p],
        D=0.1,
        Ω=50,
        Γ= 2,
        V=1
    )
    g3 = GridDynamics(node_list_updated,Y)

    println("phase difference old: ",angle(fp_old[1,:u])-angle(fp_old[2,:u]),"new: ",angle(fp_new[1,:u])-angle(fp_new[2,:u]))

    ϕ_new_1 = angle(res2[1,:u])
    ϕ_old_1 = angle(fp_old[1,:u])
end








begin
    # just ensure the correct admittance laplacian is used
    # in case the code was not executed in order
    rhs = NetworkRHS(g3)
    rhs.LY[:] = Y
    # define the initial condition as a perturbation from the fixed point
    x0 = copy(fp_new)
    #print(x0)
    x0[2, :ω] += 0.2 # perturbation on the ω of the first node
    #x0[n, :int, i] : access to the i-th internal variables of the n-th node
    #print(x0[2, :u])# : access to the complex voltage of the n-th node
    #print(x0[2, :θ])
    #x0[n, :v] : access to the magnitude of the voltage of the n-th node
    #x0[n, :φ] : access to the voltage angle of the n-th node
    timespan = (0.0,50.)
    # solve it
    sol = solve(g, x0, timespan);
end

begin
    pl_v = plot(sol, :, :v, legend = (0.4, 1.), ylabel=L"V [p.u.]")
    pl_p = plot(sol, :, :p, legend = (0.8, 0.95), ylabel=L"p [p.u.]")#, label=p_labels)
    pl_ω = plot(sol,:, :ω, legend = (0.8, 0.7), ylabel=L"\omega \left[rad/s\right]")# color=ω_colors)#label=ω_labels,
    pl = plot(
        pl_v,
        pl_p, pl_ω;
        layout=(3,1),
        size = (500, 500),
        lw=3,
        xlabel=L"t[s]"
        )
    savefig(pl, "2node-swing-minimal_fp_new.pdf")
    #display(pl)
end
