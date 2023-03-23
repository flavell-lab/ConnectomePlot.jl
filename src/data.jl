# connectome
const path_connectome_white = joinpath(@__DIR__, "..", "data", "white_1986_whole.json")
const data_connectome_white = JSON.parsefile(path_connectome_white, dicttype=Dict, inttype=Int64)

# 2d embedding data
const path_connectome_plot = joinpath(@__DIR__, "..", "data", "connectome_diagram_pos.h5")
const path_connectome_p_plot = joinpath(@__DIR__, "..", "data", "connectome_diagram_pharynx_pos.h5")
const dict_pos_z = h5read(path_connectome_plot, "z")
const dict_pos_v2 = h5read(path_connectome_plot, "v2")
const dict_pos_v3 = h5read(path_connectome_plot, "v3")
const dict_pos_z_p = h5read(path_connectome_p_plot, "z")
const dict_pos_v2_p = h5read(path_connectome_p_plot, "v2")
const dict_pos_v3_p = h5read(path_connectome_p_plot, "v3");