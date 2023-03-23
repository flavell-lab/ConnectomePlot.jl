# ConnectomePlot.jl
Example usage:
```julia
using ConnectomePlot
g = get_graph_white_lr()
list_sensory, list_muscle = ConnectomePlot.get_sensory_muscle(g)

dict_x = ConnectomePlot.dict_pos_v2
dict_y = ConnectomePlot.dict_pos_z
dict_rgba = Dict("AVA"=>[1,0,0,1], "SMDD"=>[0,1,0,1])
color_connectome(g, list_muscle, dict_x, dict_y, dict_rgba)
```
