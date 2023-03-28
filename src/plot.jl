pyb_slice(i,j) = pycall(pybuiltin("slice"), PyObject, i,j)

function rescale_to_range(value::Float64, input_range::Tuple{Float64, Float64},
    output_range::Tuple{Float64, Float64})
    input_min, input_max = input_range
    output_min, output_max = output_range

    if input_min == input_max
        error("Input range cannot have equal min and max values.")
    end

    # Normalize the input value to a range of [0, 1]
    normalized_value = (value - input_min) / (input_max - input_min)

    # Scale the normalized value to the output range
    rescaled_value = output_min + (normalized_value * (output_max - output_min))

    return rescaled_value
end

"""
    color_connectome(g_plot, list_node_rm, dict_x, dict_y, dict_rgba;
        default_rgba=[0.,0.,0.,0.05], node_size=50, edge_color=(0.7,0.7,0.7,0.1),
        edge_thicness_scaler=0.2)

Color the connectome graph.

# Arguments
- `g_plot::PyCall.PyObject`: graph object
- `list_node_rm::Vector{String}`: list of nodes to be removed
- `dict_x::Dict{String,Float64}`: dictionary of x position of each node
- `dict_y::Dict{String,Float64}`: dictionary of y position of each node
- `dict_rgba::Dict{String,Vector{Float64}}`: dictionary of rgba color of each node
- `default_rgba::Vector{Float64}`: default rgba color
- `node_size::Int64`: node size
- `edge_color::Vector{Float64}`: edge color
- `edge_thicness_scaler::Float64`: edge thickness scaler
"""
function color_connectome(g_plot, list_node_rm, dict_x, dict_y, dict_rgba;
    default_rgba=[0.,0.,0.,0.05], node_size=50, edge_color=(0.7,0.7,0.7,0.1),
    edge_thicness_scaler=0.2)
    @assert(collect(keys(dict_x)) == collect(keys(dict_y)))

    dict_pos = Dict()
    dict_node_color = Dict()

    # graph: remove nodes
    g = py_copy.deepcopy(g_plot)
    for node = list_node_rm
        g.remove_node(node)
    end

    # position and color
    for neuron = collect(keys(dict_x))
        q_color_saved = false
        dict_pos[neuron] = Float64[dict_x[neuron], dict_y[neuron]]
        feature_ = zeros(3)

        if !occursin(r"[A-Z]{2}\d", neuron) # check if not vc motor
            class, dv, lr = get_neuron_class(neuron)
            
            class_dv = class
            if !(dv == "missing" || dv == "undefined")
                class_dv = class * dv
            end
            
            if haskey(dict_rgba, class_dv)
                dict_node_color[neuron] = dict_rgba[class_dv]
                q_color_saved = true
            else
                # println("$class missing in class dict")
            end
        end # if not vc motor
        
        if !q_color_saved
            dict_node_color[neuron] = default_rgba
        end
    end # neuron

    # remove nodes that are not in the position dict
    list_node = collect(g.nodes())
    for node = list_node
        if !haskey(dict_pos, node)
            # println("removing node $node")
            g.remove_node(node)
        end
    end    

    list_node_color = hcat([dict_node_color[node] for node = g.nodes()]...)'
    nodes = py_nx.draw_networkx_nodes(g, dict_pos, node_size=node_size, node_color=list_node_color)
    nodes.set_edgecolor("none")
    py_nx.draw_networkx_edges(g, dict_pos, style="-", arrows=false, edge_color=edge_color,
        edgelist=[(u,v) for (u,v) =  g.edges],
        width=[g.edges.get((u,v))["weight"] * edge_thicness_scaler for (u,v) = g.edges])     

end

function color_connectome_kde(g_plot, list_node_rm, dict_x::Dict, dict_y::Dict, dict_v::Dict,
    f_select::Function; f_feature::Function=identity, default_rgba=[0.,0.,0.,0.05], node_size=50,
    edge_color=(0.7,0.7,0.7,0.1), edge_thicness_scaler=0.2,
    cmap=ColorMap("viridis"), vmin::Float64=0., vmax::Float64=1.,
    figsize=(3,3), n_control=10000, f_control_var::Function=std, verbose=true)
    ## graph: remove nodes
    g = py_copy.deepcopy(g_plot)
    for node = list_node_rm
        g.remove_node(node)
    end

    ## color dict
    dict_rgba = Dict()
    for (k,v) = dict_v
        v_ = clamp(f_feature(v), vmin, vmax)
        v_ = rescale_to_range(v_, (vmin, vmax), (0.,1.))
        dict_rgba[k] = collect(cmap(v_))
    end

    ## plot
    fig = figure(figsize=figsize)
    gs = matplotlib.gridspec.GridSpec(4,4) # row, col
    
    ## scatter
    ax_main = subplot(get(gs, (pyb_slice(1,4),pyb_slice(0,3))))
    color_connectome(g_plot, list_node_rm, dict_x, dict_y, dict_rgba,
        default_rgba=default_rgba, node_size=node_size, edge_color=edge_color,
        edge_thicness_scaler=edge_thicness_scaler)
    
    ## plot limits
    ax_xlim = gca().get_xlim()
    ax_ylim = gca().get_ylim()
    ax_Δx = (ax_xlim[2] - ax_xlim[1]) / 100
    ax_Δy = (ax_ylim[2] - ax_ylim[1]) / 100
    ax_Δratio = ax_Δy / ax_Δx
    rg_x = ax_xlim[1]:ax_Δx:ax_xlim[2]
    rg_y = ax_ylim[1]:ax_Δy:ax_ylim[2]
   
    list_x, list_y, list_f = get_connectome_plot_lists(dict_x, dict_y, dict_v, f_select)
    @assert(length(list_x) == length(list_y) == length(list_f))

    idx_all = 1:length(list_f)
    idx_select = findall(f_select.(list_f))
    n_neuron_select = length(idx_select)

    if n_neuron_select < 3
        error("n_neuron_select < 3")
    end

    rand_x_kde = zeros(length(rg_x), n_control)
    rand_y_kde = zeros(length(rg_y), n_control)

    ## random sampling among the recorded neurons
    if verbose
        println("neuron selected: $n_neuron_select \
        percentage: $(round(n_neuron_select/length(list_f)*100, digits=2))")
    end

    if verbose
        println("random sampling among the recorded neurons. trial: $n_control")
    end
    @showprogress for i_trial = 1:n_control
        idx_rand = sample(idx_all, n_neuron_select, replace=false)
        kd_x_rand = kde(list_x[idx_rand])
        kd_y_rand = kde(list_y[idx_rand])
        ik_x_rand = InterpKDE(kd_x_rand)
        ik_y_rand = InterpKDE(kd_y_rand)
        
        for (i_x,x) = enumerate(rg_x)
            rand_x_kde[i_x, i_trial] = pdf(ik_x_rand,x)
        end
        for (i_y,y) = enumerate(rg_y)
            rand_y_kde[i_y, i_trial] = pdf(ik_y_rand,y)
        end
    end

    ## kde plots
    kd_x_all = kde(list_x)
    kd_x_select = kde(list_x[idx_select])
    pdf_x = [pdf(kd_x_select,x) for x = rg_x]
    y1, y2, y3, _ = aggregate_var(rand_x_kde, dim=2, f_var=f_control_var)

    kd_y_all = kde(list_y)
    kd_y_select = kde(list_y[idx_select])
    pdf_y = ax_Δratio * [pdf(kd_y_select,pd) for pd = rg_y]
    x1, x2, x3, _ = aggregate_var(rand_y_kde, dim=2, f_var=f_control_var)

    plot_ymax = max(maximum(pdf_x), maximum(y3))
    plot_xmax = max(maximum(pdf_y), maximum(x3))
    plot_max = 1.05 * max(plot_ymax, plot_xmax)

    # kde top (x)
    # plot kde - selected features
    ax_top = subplot(get(gs, (0,pyb_slice(0,3))), sharex=ax_main)
    plot(rg_x, pdf_x)

    # plot kde - random control
    plot(rg_x, y2, color="gray")
    fill_between(rg_x, y1, y3, color="gray", alpha=0.2, linewidth=0)
    ylim(-5.,plot_max)
    axis("off")

    # kde right (y)
    # plot kde - selected features
    ax_right = subplot(get(gs, (pyb_slice(1,4), 3)), sharey=ax_main)
    plot(pdf_y, rg_y)

    # plot kde - random control
    plot(ax_Δratio * x2, rg_y, color="gray")
    fill_betweenx(rg_y, ax_Δratio * x1, ax_Δratio * x3, color="gray", alpha=0.2)

    xlim(-5.,plot_max)
    axis("off")

    # remove space between subplots
    subplots_adjust(wspace=0.05, hspace=0.05)
end