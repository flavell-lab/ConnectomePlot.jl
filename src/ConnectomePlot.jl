module ConnectomePlot

using PyCall, JSON, NeuroPALData, HDF5, PyPlot, DelimitedFiles, Statistics, StatsBase,
    KernelDensity, FlavellBase, ProgressMeter

include("init.jl")
include("data.jl")
include("graph.jl")
include("plot.jl")

export get_neuron_type_wh_dvlr,
    get_node_name,
    get_graph_white,
    get_graph_white_p,
    get_graph_witvliet,
    get_sensory_muscle,
    # graph.jl
    color_connectome,
    color_connectome_kde,
    # data.jl
    get_dict_pos_patched

end # module ConnectomePlot
