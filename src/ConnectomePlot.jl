module ConnectomePlot

using PyCall, JSON, NeuroPALData, HDF5, PyPlot, DelimitedFiles, Statistics, StatsBase,
    KernelDensity, FlavellBase, ProgressMeter

include("init.jl")
include("data.jl")
include("graph.jl")
include("plot.jl")
include("table.jl")

export get_neuron_type_wh_dvlr,
    get_node_name,
    get_graph_white,
    get_graph_white_p,
    get_graph_witvliet,
    get_sensory_muscle,
    # graph.jl
    color_connectome,
    color_connectome_kde,
    color_connectome_multi_kde,
    test_signifiance_connectome,
    # data.jl
    get_dict_pos_patched,
    # table.jl
    generate_check_categorization,
    get_tau,
    neuropal_aggregate_data,
    neuropal_count
end # module ConnectomePlot
