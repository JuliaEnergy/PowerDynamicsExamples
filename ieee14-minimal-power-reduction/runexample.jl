begin
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.resolve()
    Pkg.instantiate()
    cd(@__DIR__)
end

begin
    using CSV
    using DataFrames
    using PowerDynBase
    using PowerDynBase: AbstractNodeParameters
    using PowerDynSolve
    using PowerDynOperationPoint
    using LaTeXStrings
    using Plots
    using SparseArrays
end

begin
    busses_df = CSV.read("IEEE14_busses.csv")[[2,5,6,7,8,9,10]]
    df_names = [:type, :P_gen, :Q_gen, :P_load, :Q_load, :intertia, :damping]
    names!(getfield(busses_df, :colindex), df_names)
    display(busses_df)

    lines_df = CSV.read("IEEE14_lines.csv")
    df_names = [:from, :to, :R, :X, :charging, :tap_ratio]
    names!(getfield(lines_df, :colindex), df_names)
    display(lines_df)
end

begin
    println("converting dataframes to types of PowerDynamics")
    function busdf2nodelist(busses_df)
        node_list = Array{AbstractNodeParameters,1}()
        for bus_index = 1:size(busses_df)[1]
            bus_data = busses_df[bus_index,:]
            if busses_df[bus_index,:type] == "S"
                append!(node_list, [SlackAlgebraic(U=1)])
            elseif busses_df[bus_index,:type] == "G"
                append!(node_list, [SwingEqLVS(
                    H=busses_df[bus_index,:intertia]  ,
                    P=(busses_df[bus_index,:P_gen] - busses_df[bus_index,:P_load]),
                    D=busses_df[bus_index,:damping],
                    Ω=50,
                    Γ= 2,
                    V=1
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
    node_list_power_reduction = copy(node_list)
    n = node_list[1]
    node_list_power_reduction[1] = SwingEqLVS(
        H=n.H,
        P=n.P*0.9, # 10% power reduction
        D=n.D,
        Ω=n.Ω,
        Γ=n.Γ,
        V=n.V
    )
    @assert node_list != node_list_power_reduction
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

    # admittance laplacian
    LY = linedf2LY(lines_df, length(node_list))
end

# create network dynamics object
g = GridDynamics(node_list, LY)
g_power_reduction = GridDynamics(node_list_power_reduction, LY)

# find the fixed point = normal operation point
fp = getOperationPoint(g, ones(SystemSize(g)))

begin
    # solve before fault (i.e. simply staying on the fixed point)
    sol1 = solve(g, fp, (0., 2.))
    final_state1 = sol1(:final)
    # solve after the fault
    sol2 = solve(g_power_reduction, State(g_power_reduction, convert(Vector, final_state1)), (2., 3.))
    final_state2 = sol2(:final)
    # solve after clearance of the fault
    sol3 = solve(g, State(g, convert(Vector, final_state2)), (3., 5.))
    sol = CompositeGridSolution(sol1, sol2, sol3)
end

begin
    # pl_v = plot(sol, :, :v, legend = (0.4, 1.), ylabel=L"V [p.u.]")
    pl_p = plot(sol, :, :p, legend = (0.8, 0.95), ylabel=L"p [p.u.]", label=p_labels)
    pl_ω = plot(sol, swing_indices, :ω, legend = (0.8, 0.7), ylabel=L"\omega \left[rad/s\right]", label=ω_labels, color=ω_colors, ylims=(-1, 1))
    pl = plot(
        # pl_v,
        pl_p, pl_ω;
        layout=(2,1),
        size = (500, 500),
        lw=3,
        xlabel=L"t[s]"
        )
    display(pl)
end
