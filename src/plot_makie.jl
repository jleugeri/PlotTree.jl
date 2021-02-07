using JSServe, GLMakie, AbstractPlotting, DataStructures
import ColorTypes: RGB

struct Port{W,I}
    name::I
end
Port{W}(name::I) where {W,I} = Port{W,I}(name)

struct Branch{I}
    name::I
    branches::Vector{Branch{I}}
    ports::Vector{Port}
end
Branch(i::I, branches, ports) where I = Branch{I}(i, convert(Vector{Branch{I}},branches), ports)

tree = Branch("Soma", [
    Branch("B1", [
    ], [
        Port{:pos}("S1"),
    ]),
    Branch("B2", [
        Branch("B21", [
        ], [
            Port{:neg}("S2"),
        ]),
        Branch("B22", [
            Branch("B221", [
            ], [
                Port{:neg}("S3a"),
            ]),
            Branch("B222", [
            ], [
                Port{:neg}("S3b"),
            ]),
            Branch("B223", [
            ], [
                Port{:neg}("S3c"),
            ]),
            Branch("B224", [
            ], [
                Port{:neg}("S3d"),
            ]),
            Branch("B225", [
            ], [
                Port{:neg}("S3e"),
            ]),
            Branch("B226", [
            ], [
                Port{:neg}("S3f"),
            ]),
        ], [
            Port{:pos}("S4"),
        ]),
    ], []),
    Branch("B3", [
    ], [
        Port{:pos}("S5"),
    ])
], [])

# if obj is an observable dict-type holding named values, get named value ...
maybe_get(obj::Node, key) = if isa(obj[],Union{DefaultDict,Dict})
    @lift $obj[key]
else
    obj
end
# if obj is a dict-type holding named values, get named value ...
maybe_get(obj::Union{DefaultDict,Dict}, key) = obj[key]
# ... otherwise return the obj itself
maybe_get(obj, key) = obj

function serialize_tree(tree::Branch{I}, l, ω) where {I}
    sectors = Float64[]
    depths = Float64[]
    all_points = Vector{Pair{I,Point2f0}}[]
    all_points_flat = Pair{I,Point2f0}[]
    all_ports_flat = Pair{I,Vector{Port}}[tree.name=>tree.ports]
    all_parents_flat = Pair{I,I}[]

    # go through all branches once to collect information
    for subtree in tree.branches
        # get angle and depth of sector
        α,d,points,ports,parents = serialize_tree(subtree, l, ω)
        # compute depth of new sector
        ll = maybe_get(l, subtree.name)
        c = √(ll^2+d^2-2*ll*d*cos(π-α/2))
        # compute angle of new sector
        β=2acos((ll^2+c^2-d^2)/(2ll*c))

        push!(sectors, β+ maybe_get(ω, subtree.name))
        push!(depths, c)
        push!(all_points, points)
        append!(all_ports_flat, ports)
        append!(all_parents_flat, parents)
        push!(all_parents_flat, subtree.name=>tree.name)
    end

    # calculate total angle and depth for current (sub-)tree
    sector = sum(sectors)
    depth = isempty(depths) ? 0.0 : maximum(depths)

    # calculate angles for all branches
    branch_angles = cumsum(sectors) .- sectors./2 .- sector/2

    # go through all branches again and apply branch-specific transformations
    for (branch, branch_angle, points) in zip(tree.branches, branch_angles, all_points)
        # shift by l and rotate by `branch_angle`
        c=cos(branch_angle)
        s=sin(branch_angle)
        transform = ((x,y),) -> (c*x-s*(y+l),s*x+c*(y+l))

        # add branch for branch
        push!(all_points_flat, branch.name=>transform(Point2f0(0.0,0.0)))
        
        # keep branches from branches' subtree
        if !isempty(points)            
            append!(all_points_flat, map(((name,pts),) -> name=>transform(pts), points))
        end
    end

    return (sector=sector, depth=depth, nodes=all_points_flat, ports=all_ports_flat, parents=all_parents_flat)
end

function AbstractPlotting.default_theme(scene::AbstractPlotting.SceneLike, ::Type{<: AbstractPlotting.Plot(Branch)})
    Theme(
        color=RGB(0.9,0.9,0.9),
        branch_width=0.1,
        branch_length=1.0,
        angle_between=10/180*pi,
        show_port_labels=true,
        xticks = [],
        port_marker = x -> (marker=isa(x,Port{:pos}) ? "▲" : "o", color=RGB(0.9,0.9,0.9)),
        port_label = x -> (x.name, Point2f0(-0.1,-0.1), :textsize=>0.25, :align=>(:right,:center))
    )
end

function AbstractPlotting.plot!(treeplot::AbstractPlotting.Plot(Branch))
    # get the actual object to plot
    tree = to_value(treeplot[1])

    # get all nodes, their ports and parents in flat format
    serialized = lift(treeplot[:branch_length],treeplot[:angle_between]) do l,ω
        ser=serialize_tree(tree,l,ω)
        push!(ser.nodes, tree.name => Point2f0(0.0,0.0))
        ser
    end
    parent = DefaultDict(tree.name, serialized[].parents...)

    # plot branches
    for (name,parent_name) in serialized[].parents
        c  = maybe_get(treeplot[:color], name)
        w1 = maybe_get(treeplot[:branch_width], name)
        w2 = maybe_get(treeplot[:branch_width], parent_name)

        # dynamically recompute polygon
        branch_poly = lift(w1, w2, serialized) do w1,w2,ser
            node_dict = Dict(ser.nodes...)
            b1 = node_dict[name]
            b2 = node_dict[parent_name]
            normal = [0 1; -1 0]*(b2-b1)
            normal /= sqrt(normal'*normal)*2
            Point2f0[
                -normal*w1+b1,
                 normal*w1+b1,
                 normal*w2+b2,
                -normal*w2+b2
            ]
        end
        
        # draw polygon for the branch
        poly!(treeplot, branch_poly, color=c)

        # draw circle to cap off branch
        poly!(treeplot, lift(w2,serialized) do w2,ser
            node_dict = Dict(ser.nodes...)
            b2 = node_dict[name]
            Circle(b2, w2/2)
        end, color=c)
    end

    # draw polygon for the root
    c = maybe_get(treeplot[:color], tree.name)
    w = maybe_get(treeplot[:branch_width], tree.name)
    root_poly = lift(w) do w
        Point2f0[(-w/2*√(3), -w/2), (0,w), (w/2*√(3), -w/2)]
    end
    println(c)
    poly!(treeplot, root_poly, color=c)
    # lines!(treeplot, Point2f0[(0.0, 0.0),(0.0, -0.5)], linewidth=treeplot[:branch_width], color=c)

    # ports_locations = Pair{String,Point2f0}[]

    # # plot ports & labels
    # for (name,branch) in branches
    #     for (port,loc) in zip(ports[name], LinRange(branch..., length(ports[name])+2)[2:end-1])
    #         scatter!(treeplot, [loc]; port_marker(port)...)
    #         label = port_label(port)
    #         text,offset = label[1:2]
    #         args = label[3:end] 
            
    #         text!(treeplot, text, position=loc+offset, visible=treeplot[:show_port_labels]; args...)
    #         push!(ports_locations, port.name=>loc)
    #     end
    # end
    

    # treeplot.attributes[:ports] = ports_locations
    treeplot
end

scene, layout = layoutscene(resolution = (1200, 900))
ax = layout[1, 1] = Axis(scene, title="Neuron", autolimitaspect=1)
branch_names = ["Soma", "B1", "B2", "B21", "B22", "B221", "B222", "B223", "B224", "B225", "B226", "B3", ]

color = Node(Dict(name=>rand(RGB) for name in branch_names))
#DefaultDict(Observable(RGB(0.9,0.9,0.9)), "B22" => Observable(RGB(0.9,0.1,0.1)))

ls = labelslidergrid!(scene, ["Inner angle", "Width"], [0.01:0.01:1π, 0.001:0.001:0.25]; format = x -> "$(round(x,digits=1))")
angle_between = ls.sliders[1].value
branch_width = ls.sliders[2].value
plot!(ax, tree, angle_between=angle_between, branch_width=branch_width, color=color, show_port_labels=false)
hidespines!(ax)
hidedecorations!(ax)
# ports = to_value(plt.attributes[:ports])
#lines!(ax, Point2f0[(-1,3), ports[3][2]])

layout[2, 1] = ls.layout
display(scene)

c = cgrad(:magma)
record(scene, "blinky_neuron.mp4", LinRange(0,2*pi,1000); framerate=30) do t
    print(".")
    for (i,name) in enumerate(branch_names)
        color[][name] = c[sin(i*t)/2+0.5]
    end
    # workaround: force update on color
    color[] = color[]
end
