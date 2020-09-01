using PowerDynamics: symbolsof
using Plots: plot, get_color_palette, plot_color
using LaTeXStrings: latexstring, @L_str

function create_plot(sol)
    swing_indices = findall(n -> :ω ∈ symbolsof(n), sol.powergrid.nodes)
    ω_colors = reshape(get_color_palette(:auto, plot_color(:white), 8)[swing_indices], (1,length(swing_indices)))
    ω_labels = reshape([latexstring(string(raw"\omega", "_{$i}")) for i=swing_indices], (1, length(swing_indices)))
    p_labels = reshape([latexstring(string(raw"p", "_{$i}")) for i=1:length(sol.powergrid.nodes)], (1, length(sol.powergrid.nodes)))

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
    return pl
end
