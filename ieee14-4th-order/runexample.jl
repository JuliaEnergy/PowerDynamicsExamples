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
    using LaTeXStrings
    using Plots
    # Plots.scalefontsizes(0.8)
    using SparseArrays
end

begin
    lines_df = CSV.read("IEEE14_lines.csv")
    df_names = [:from, :to, :R, :X, :charging, :tap_ratio]
    names!(getfield(lines_df, :colindex), df_names)

    busses_df = CSV.read("IEEE14_busses.csv")[[2,5,6,7,8,9,10,12,13,14,15,16,17]]
    df_names = [:type, :P_gen, :Q_gen, :P_load, :Q_load, :inertia, :damping,:X_d,:X_d_dash,:T_d_dash,:X_q,:X_q_dash,:T_q_dash]
    names!(getfield(busses_df, :colindex), df_names)
end
#busses_df

begin
    println("converting dataframes to types of DPSA")
    function busdf2nodelist(busses_df)
        node_list = Array{AbstractNodeParameters,1}()
        for bus_index = 1:size(busses_df)[1]
            bus_data = busses_df[bus_index,:]
            if busses_df[bus_index,:type] == "S"
                append!(node_list, [SlackAlgebraic(U=1)])
            elseif busses_df[bus_index,:type] == "G"
                append!(node_list, [FourthEq(
                    H=busses_df[bus_index,:inertia]  ,
                    P=(busses_df[bus_index,:P_gen] - busses_df[bus_index,:P_load]),
                    D=busses_df[bus_index,:damping],
                    T_d_dash =busses_df[bus_index,:T_d_dash],
                    T_q_dash =busses_df[bus_index,:T_q_dash]+0.1,
                    X_d =busses_df[bus_index,:X_d],
                    X_q =busses_df[bus_index,:X_q],
                    X_d_dash =busses_df[bus_index,:X_d_dash],
                    X_q_dash =busses_df[bus_index,:X_q_dash],
                    Ω=50,
                    E_f=1
                )])
            elseif busses_df[bus_index,:type] == "L"
                append!(node_list, [PQAlgebraic(
                    S= -busses_df[bus_index,:P_load] - im*busses_df[bus_index,:Q_load]
                )])
            end
        end
        return node_list
    end

    node_list = busdf2nodelist(busses_df)
    # some preparation for plotting later
    swing_indices = findall(busses_df[:type] .== "G")
    ω_colors = reshape(Plots.get_color_palette(:auto, plot_color(:white), 8)[swing_indices], (1,length(swing_indices)))
    ω_labels = reshape([latexstring(string(raw"\omega", "_{$i}","[$(busses_df[i,:type])]")) for i=swing_indices], (1, length(swing_indices)))
    p_labels = reshape([latexstring(string(raw"p", "_{$i}","[$(busses_df[i,:type])]")) for i=1:length(node_list)], (1, length(node_list)))
end

begin
    function linedf2LY(lines_df, num_nodes)
        Y = spzeros(Complex, num_nodes, num_nodes)
        for line_index = 1:size(lines_df)[1]
            from = lines_df[line_index,:from]
            to = lines_df[line_index,:to]
            if (from > num_nodes) || (to > num_nodes)
                warn("Skipping line $line_index from $from to $(to)!")
                continue
            end
            admittance = 1/(lines_df[line_index,:R] + im*lines_df[line_index,:X])
            println("$from --> $to : $admittance")
            Y[from, to] = - admittance
            Y[to, from] = - admittance
            Y[from, from] += admittance # note the +=
            Y[to, to] += admittance # note the +=
        end
        return Y
    end

    function linedf2tabular(df)
        lines = ["$(getfield(row, :row)) & $(row[:from]) & $(row[:to]) & $(row[:R]) & $(row[:X])" for row in eachrow(df)]
        string(raw"""\begin{tabular}{|c||c|c|c|c|}
        \toprule
        line number & from bus & to bus & $ R\, [p.u.]$ & $ X\, [p.u.]$ \\\midrule""",
        join(lines, raw"\\\hline"), raw"""\\
        \bottomrule
        \end{tabular}""")
    end

    # admittance laplacian
    LY = linedf2LY(lines_df, length(node_list))
    LY_default = copy(LY) # just save it, so line tripping can be implemented easier later
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
g = GridDynamics(node_list, LY)
# search for fixed point

# find the fixed point = normal operation point
fp = operationpoint(g, ones(SystemSize(g)))

begin
    # just ensure the correct admittance laplacian is used
    # in case the code was not executed in order
    rhs = NetworkRHS(g)
    rhs.LY[:] = LY_default
    # define the initial condition as a perturbation from the fixed point
    x0 = copy(fp)
    x0[1, :ω] += .2 # perturbation on the ω of the first node
    #x0[n, :int, i] : access to the i-th internal variables of the n-th node
    #x0[n, :u] : access to the complex voltage of the n-th node
    #x0[n, :v] : access to the magnitude of the voltage of the n-th node
    #x0[n, :φ] : access to the voltage angle of the n-th node
    timespan = (0.0,.3)
    # solve it
    sol = solve(g, x0, timespan);
end

begin
    pl_v = plot(sol, :, :v, legend = (0.8, 1.), ylabel=L"V [p.u.]")
    pl_p = plot(sol, :, :p, legend = (0.8, 0.95), ylabel=L"p [p.u.]", label=p_labels)
    pl_ω = plot(sol, swing_indices, :ω, legend = (0.8, 0.7), ylabel=L"\omega \left[rad/s\right]", label=ω_labels, color=ω_colors)
    pl = plot(
        pl_v,
        pl_p, pl_ω;
        layout=(3,1),
        size = (500, 500),
        lw=3,
        xlabel=L"t[s]"
        )
    savefig(pl, "ieee14-frequency-perturbation.pdf")
    display(pl)
end


begin
    fault_line = (1, 5)
    @assert fault_line[1] < fault_line[2] "order important to kill the line in the data frame"
    idxs = findall(.~((lines_df[:from] .== fault_line[1]) .& (lines_df[:to] .== fault_line[2])))
    lines_df_fault = copy(lines_df)[idxs, :]
    LY_fault = linedf2LY(lines_df_fault, length(node_list))
    @show LY_default - LY_fault
    rhs = NetworkRHS(g)
    rhs.LY[:] = LY_fault
    # start from the fixed point of the original system
    x0 = copy(fp)
    timespan = (0.0,100.0)
    # # solve it
    sol = solve(g, x0, timespan);
end



begin
    # pl_v = plot(sol, :, :v, legend = (0.4, 1.), ylabel=L"V [p.u.]")
    pl_p = plot(sol, :, :p, legend = (0.8, 0.95), ylabel=L"p [p.u.]", label=p_labels)
    pl_ω = plot(sol, swing_indices, :ω, legend = (0.8, 0.7), ylabel=L"\omega \left[rad/s\right]", label=ω_labels, color=ω_colors)
    #pl_u = plot(sol, swing_indices, :u, legend = (0.8, 0.7), ylabel=L"u [p.u.]", label=label, color=ω_colors)

    pl = plot(
        # pl_v,
        pl_p, pl_ω;
        layout=(2,1),
        size = (500, 500),
        lw=3,
        xlabel=L"t[s]"
        )
    savefig(pl, "ieee14-line-tripping.pdf")
    display(pl)
end
