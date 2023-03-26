# connectome
const path_connectome_white = joinpath(@__DIR__, "..", "data", "white_1986_whole.json")
const data_connectome_white = JSON.parsefile(path_connectome_white, dicttype=Dict, inttype=Int64)

# 2d embedding data
const path_connectome_plot = joinpath(@__DIR__, "..", "data", "connectome_diagram_pos.h5")
const path_connectome_p_plot = joinpath(@__DIR__, "..", "data", "connectome_diagram_pharynx_pos.h5")
const dict_pos_z_non_p = h5read(path_connectome_plot, "z")
const dict_pos_v2_non_p = h5read(path_connectome_plot, "v2")
const dict_pos_v3_non_p = h5read(path_connectome_plot, "v3")
const dict_pos_z_p = h5read(path_connectome_p_plot, "z")
const dict_pos_v2_p = h5read(path_connectome_p_plot, "v2")
const dict_pos_v3_p = h5read(path_connectome_p_plot, "v3")

const dict_pos_z = merge(dict_pos_z_non_p, dict_pos_z_p)
const dict_pos_v2 = merge(dict_pos_v2_non_p, dict_pos_v2_p)
const dict_pos_v3 = merge(dict_pos_v3_non_p, dict_pos_v3_p)