function get_neuron_type_wh_lr(class)
    list_motor_prefix = ["AS", "VD", "VC", "VB", "VA", "DA", "DB", "DD"]
    
    REF = NeuroPALData.NEURON_REF_DICT
    
    if haskey(REF, class)
        return REF[class]["type"]
    elseif any(startswith.(class, list_motor_prefix))
        return "motorneuron"
    elseif class in ["LegacyBodyWallMuscles", "DefecationMuscles"] || startswith(class, "pm")
        return "muscle"
    else
        return "unknown"
    end
end

function get_node_name(neuron; dv=true)
    REF = NeuroPALData.NEURON_REF_DICT
    if haskey(REF, neuron)
        neuron_ = REF[neuron]
        class_ = neuron_["class"]
        if !dv
            return class_
        else
            if neuron_["DV"] != "undefined"
                return class_ * neuron_["DV"]
            else
                return class_
            end
        end
    else
        return neuron
    end
end

# generate graph
function get_graph_white_lr(min_n_edge=1, merge_dv=false)
    list_connectome = [data_connectome_white]
    
    list_neuron = []
    for connectome = list_connectome
        append!(list_neuron, map(x->get_node_name(x["pre"], dv=merge_dv), connectome))
        append!(list_neuron, map(x->get_node_name(x["post"], dv=merge_dv), connectome))
    end
    list_neuron = sort(unique(list_neuron))
        
    g = py_nx.DiGraph()
    for neuron = list_neuron
        g.add_node(neuron)
    end
        
    dict_synapese = Dict()
    for connectome = list_connectome
        for synapse = connectome
            syn_type = synapse["typ"] == 0 ? "chemical" : "electrical"

            pre = synapse["pre"]
            post = synapse["post"]
            edge_count = sum(synapse["syn"])
                        
            k = (pre,post,syn_type)
            if haskey(dict_synapese, k)
                dict_synapese[k] += edge_count
            else
                dict_synapese[k] = edge_count
            end
        end
    end
     
    # add edge
    dict_synapse_combine = Dict()
    for ((pre,post,syn_type), edge_count) = dict_synapese
        if pre != post
            if edge_count > min_n_edge
                k = (pre,post)
                if haskey(dict_synapse_combine, k)
                    dict_synapse_combine[k] += edge_count
                else
                    dict_synapse_combine[k] = edge_count
                end
                
                if syn_type == "electrical" # treat electrical synapse as bidirectional
                    k = (post,pre)
                    if haskey(dict_synapse_combine, k)
                        dict_synapse_combine[k] += edge_count
                    else
                        dict_synapse_combine[k] = edge_count
                    end
                end
            end # if edge_count > min_n_edge
        end # if pre != post
    end # for dict_synapese
    
    for ((pre,post), edge_count) = dict_synapse_combine
        g.add_edge(pre, post, weight=(edge_count))  
    end

    # remove orphan node
    for node = collect(g.nodes())
        if g.in_degree(node) + g.out_degree(node) == 0
            g.remove_node(node)
            # println("removing $node")
        end
    end
    
    g
end

function get_graph_white_lr_p(min_n_edge=1)
    g_wh_lr_p = get_graph_white_lr(min_n_edge=min_n_edge)
    g = g_wh_lr_p

    # remove orphan node, pharyngeal
    for node = collect(g.nodes())
        if g.in_degree(node) + g.out_degree(node) == 0
            g.remove_node(node)
            # println("removing $node orphaned")
            continue
        end

        if haskey(NeuroPALData.NEURON_REF_DICT, node)
            if NeuroPALData.NEURON_REF_DICT[node]["note"] != "pharynx"
                g.remove_node(node)
                # println("removing $node non-pharynx")
            else
                # println("pharynx node $node")
            end
        else
            g.remove_node(node)
            # println("removing $node not in dict")
        end
    end

    g
end

 function get_sensory_muscle(g)
    list_node = collect(g.nodes)
    list_sensory = String[]
    list_muscle = String[]

    for node = list_node
        type_ = get_neuron_type_wh_lr(node)
        if type_ == "sensory"
            push!(list_sensory, node)
        elseif startswith(type_, "muscle")
            push!(list_muscle, node)
        end
    end
    
    list_sensory, list_muscle
end