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
    using PowerDynBase: AbstractNodeParameters
    using PowerDynOperationPoint
    using LaTeXStrings
    using Plots
    # Plots.scalefontsizes(0.8)
    using SparseArrays
end

# parameterization
begin
    B = -5
    I_r = 1
end


begin
    num_nodes=2
    println("creating minimal two node example of one slack node and one CSIMinimal node")
    node_list = Array{AbstractNodeParameters,1}()
    append!(node_list, [CSIMinimal(
        I_r=I_r,
                )])
    append!(node_list,[SlackAlgebraic(U=1)])
end

begin
    admittance = 1im*B
    Y = spzeros(Complex, num_nodes, num_nodes)
    Y[1,2] = - admittance
    Y[2 ,1] = - admittance
    Y[1, 1] += admittance # note the +=
    Y[2, 2] += admittance # note the +=# just save it, so line tripping can be implemented easier later
end

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

fp = getOperationPoint(g, ones(SystemSize(g)))#fp[1,:θ]

begin
    # just ensure the correct admittance laplacian is used
    # in case the code was not executed in order
    rhs = NetworkRHS(g)
    rhs.LY[:] = Y
    # define the initial condition as a perturbation from the fixed point
    x0 = copy(fp)
    #print(x0)
    x0[2, :v] += .2 # perturbation on the ω of the first node
    #x0[n, :int, i] : access to the i-th internal variables of the n-th node
    #print(x0[1, :ω])# : access to the complex voltage of the n-th node
    #print(x0[2, :θ])
    #x0[n, :v] : access to the magnitude of the voltage of the n-th node
    #x0[n, :φ] : access to the voltage angle of the n-th node
    timespan = (0.0,100.)
    # solve it
    sol = solve(g, x0, timespan);
end

begin
    #x0[:,:int,1]
    pl_v = plot(sol, :, :v, legend = (0.4, 1.), ylabel=L"V [p.u.]")
    pl_p = plot(sol, :, :p, legend = (0.8, 0.95), ylabel=L"p [p.u.]")#, label=p_labels)
    #pl_i = plot(sol, :, :i, legend = (0.8, 0.95), ylabel=L"i [p.u.]")#, label=p_labels)
    #pl_ω = plot(sol, 1, :ω, legend = (0.8, 0.7), ylabel=L"\omega \left[rad/s\right]")# color=ω_colors)#label=ω_labels,
    pl = plot(
        pl_v,
        pl_p;
        layout=(2,1),
        size = (500, 500),
        lw=3,
        xlabel=L"t[s]"
        )
    savefig(pl, "csi-2node-minimal.pdf")
    display(pl)
end
