using JSServe, GLMakie, AbstractPlotting, DataStructures
import ColorTypes: RGB

struct Port{W}
    name::String
end

struct Branch
    name::String
    branches::Vector{Branch}
    ports::Vector{Port}
end

struct Root
    name::String
    branches::Vector{Branch}
end

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

function localize_branches(tree::Branch, l, angle_between)
    sectors = Float64[]
    depths = Float64[]
    all_points = Vector{Pair{String,Vector{Point2f0}}}[]
    all_points_flat = Pair{String,Vector{Point2f0}}[]
    all_ports_flat = Pair{String,Vector{Port}}[tree.name=>tree.ports]

    # go through all branches once to collect information
    for subtree in tree.branches
        # get angle and depth of sector
        α,d,points,ports = localize_branches(subtree, l, angle_between)
        # compute depth of new sector
        c = √(l^2+d^2-2*l*d*cos(π-α/2))
        # compute angle of new sector
        β=2acos((l^2+c^2-d^2)/(2l*c))

        push!(sectors, β+angle_between)
        push!(depths, c)
        push!(all_points, points)
        append!(all_ports_flat, ports)
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

        # add segment for branch
        push!(all_points_flat, branch.name=>[(0.0,0.0),transform((0.0,0.0))])
        
        # keep segments from branches' subtree
        if !isempty(points)            
            append!(all_points_flat, map(((name,pts),) -> name=>transform.(pts), points))
        end
    end

    return (sector=sector, depth=depth, segments=all_points_flat, ports=all_ports_flat)
end

function AbstractPlotting.default_theme(scene::AbstractPlotting.SceneLike, ::Type{<: AbstractPlotting.Plot(Branch)})
    Theme(
        color=RGB(0.9,0.9,0.9),
        segment_width=10,
        segment_length=1.0,
        angle_between=10/180*pi,
        show_port_labels=true,
        xticks = [],
        port_marker = x -> (marker=isa(x,Port{:pos}) ? "▲" : "o", color=RGB(0.9,0.9,0.9)),
        port_label = x -> (x.name, Point2f0(-0.1,-0.1), :textsize=>0.25, :align=>(:right,:center))
    )
end

function AbstractPlotting.plot!(treeplot::AbstractPlotting.Plot(Branch))
    tree = to_value(treeplot[1])
    port_marker = to_value(treeplot[:port_marker])
    port_label = to_value(treeplot[:port_label])

    serialized = localize_branches(tree,to_value(treeplot[:segment_length]),to_value(treeplot[:angle_between]))
    segments = serialized[:segments]
    ports = Dict(serialized[:ports]...)
    ports_locations = Pair{String,Point2f0}[]

    # plot segments
    for (name,segment) in segments
        cval = to_value(treeplot[:color])
        c = isa(cval, Union{DefaultDict,Dict}) ? cval[name] : treeplot[:color]
        lines!(treeplot, segment, linewidth=treeplot[:segment_width], color=c)
        scatter!(treeplot, segment, markersize=treeplot[:segment_width], color=c, strokewidth=0)
    end

    # plot root
    cval = to_value(treeplot[:color])
    c = isa(cval, Union{DefaultDict,Dict}) ? cval[tree.name] : treeplot[:color]
    poly!(treeplot, Point2f0[(-0.25,-0.25),(0.25,-0.25),(0.0, 0.25)], color=c)
    lines!(treeplot, Point2f0[(0.0, 0.0),(0.0, -0.5)], linewidth=treeplot[:segment_width], color=c)

    # plot ports & labels
    for (name,segment) in segments
        for (port,loc) in zip(ports[name], LinRange(segment..., length(ports[name])+2)[2:end-1])
            scatter!(treeplot, [loc]; port_marker(port)...)
            label = port_label(port)
            text,offset = label[1:2]
            args = label[3:end] 
            
            text!(treeplot, text, position=loc+offset, visible=treeplot[:show_port_labels]; args...)
            push!(ports_locations, port.name=>loc)
        end
    end
    

    treeplot.attributes[:ports] = ports_locations
    treeplot
end

scene, layout = layoutscene(resolution = (1200, 900))
ax = layout[1, 1] = Axis(scene, title="Neuron", autolimitaspect=1)
branch_names = ["Soma", "B1", "B2", "B21", "B22", "B221", "B222", "B223", "B224", "B225", "B226", "B3", ]

color = Dict(name=>Observable(rand(RGB)) for name in branch_names)
#DefaultDict(Observable(RGB(0.9,0.9,0.9)), "B22" => Observable(RGB(0.9,0.1,0.1)))

plot!(ax, tree, angle_between=10/180*π, color=color, show_port_labels=false)
hidespines!(ax)
hidedecorations!(ax)
ports = to_value(plt.attributes[:ports])
#lines!(ax, Point2f0[(-1,3), ports[3][2]])
c = cgrad(:magma)

record(scene, "blinky_neuron.mp4", LinRange(0,2*pi,1000); framerate=30) do t
    print(".")
    for (i,name) in enumerate(branch_names)
        color[name][] = c[sin(i*t)/2+0.5]
    end
end
