function color_connectome(g_plot, list_node_rm, dict_x, dict_y, dict_rgba;
    default_rgba=[0.,0.,0.,0.05], node_size=50, edge_color=(0.7,0.7,0.7,0.1),
    edge_thicness_scaler=0.2)
    @assert(collect(keys(dict_x)) == collect(keys(dict_y)))

    dict_pos = Dict()
    dict_node_color = Dict()

    # graph
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

    function rescale_to_range(value::Float64, input_range::Tuple{Float64, Float64}, output_range::Tuple{Float64, Float64})
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

    function add_list_dict!(dict, key, item)
    if haskey(dict, key)
        push!(dict[key], item)
    else
        dict[key] = [item]
    end

    nothing
end