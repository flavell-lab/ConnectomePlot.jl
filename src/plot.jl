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
    py_nx.draw_networkx_nodes(g, dict_pos, node_size=node_size, node_color=list_node_color)
    py_nx.draw_networkx_edges(g, dict_pos, style="-", arrows=false, edge_color=edge_color,
        edgelist=[(u,v) for (u,v) =  g.edges],
        width=[g.edges.get((u,v))["weight"] * edge_thicness_scaler for (u,v) = g.edges])     

end
