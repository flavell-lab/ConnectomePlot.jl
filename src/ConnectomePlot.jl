module ConnectomePlot

using PyCall, JSON, NeuroPALData, HDF5, PyPlot

include("init.jl")
include("data.jl")
include("graph.jl")
include("plot.jl")

export get_neuron_type_wh_lr,
    get_graph_white_lr,
    get_graph_white_lr_p,
    get_sensory_muscle,
    # graph.jl
    color_connectome

end # module ConnectomePlot
