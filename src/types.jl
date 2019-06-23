abstract type AbstractNode end

struct Node{T,L} <: AbstractNode
    children::Vector{<:AbstractNode}
    threshold::T
    label::L
end
Node(label) = Node(Node[], 0, label)

struct TreePlotCfg
    scale_mm
    segment_height
    segment_width
    text_width
    connector_height
    segment_color
    connector_color
    label_color
    threshold_color
    stroke_color
    stroke_width
    font_size
end


struct Scene
    num_rows
    num_columns
    objects
    cfg
end

struct Segment{Class}
    row
    column
    cfg
    Segment(row,column,s::Symbol=:internal;cfg=TreePlotCfg()) = new{s}(row,column,cfg)
end

struct Connector{Shape}
    row
    column
    cfg
    Connector(row,column,s::Symbol;cfg=TreePlotCfg()) = new{s}(row,column,cfg)
end

struct Label{Class}
    row
    column
    text
    cfg
    Label(row,column,text,s::Symbol;cfg=TreePlotCfg()) = new{s}(row,column,text,cfg)
end


function TreePlotCfg(;scale_mm=1, segment_height=10, segment_width=3, text_width=4, connector_height=5, segment_color="#babdb6", connector_color="#555753", label_color="#000000", threshold_color="#555753", stroke_color="#000000", stroke_width=0.3, font_size=6)
    @assert connector_height >= segment_width "connector_height ($(connector_height)) cannot be smaller than segment_width ($(segment_width))"
    TreePlotCfg(scale_mm, segment_height, segment_width, text_width, connector_height, segment_color, connector_color, label_color, threshold_color, stroke_color, stroke_width, font_size)
end

get_column_offset(cfg::TreePlotCfg, column) = (column-1)*(cfg.segment_width+2*cfg.text_width)+cfg.text_width
get_row_offset(cfg::TreePlotCfg, row) = (row-1)*(cfg.segment_height+cfg.connector_height)+cfg.connector_height

function group_subtree!(n::Node, start, level, objects=[])
    if length(objects) < level
        push!(objects, [])
    end

    total_width = 0
    for child ∈ n.children
        total_width += group_subtree!(child, start+total_width, level+1, objects)
    end
    total_width = total_width == 0 ? 1 : total_width

    push!(objects[level], (start+cld(total_width+1, 2)-1, n))
    return total_width
end

function Scene(tree::Node, drop_default_thresholds=true; kwargs...)
    cfg = TreePlotCfg(;kwargs...)
    rows = []
    num_columns = group_subtree!(tree, 1, 1, rows)
    reverse!(rows)
    objects = []

    # iterate all rows
    for (i,row) ∈ enumerate(rows)
        idx = 0
        # iterate all nodes in the current level
        for (j,(col, node)) ∈ enumerate(row)
            num_children = length(node.children)
            # draw connectors to the children
            if num_children == 0
                #push!(objects, Connector(i,col, :cap, cfg=cfg))
                if node.threshold != 0 || ~drop_default_thresholds
                    push!(objects, Label(i, col, node.threshold, :connector, cfg=cfg))
                end
            elseif num_children == 1
                push!(objects, Connector(i,col, :up, cfg=cfg))
                if node.threshold != 1 || ~drop_default_thresholds
                    push!(objects, Label(i, col, node.threshold, :connector, cfg=cfg))
                end
            else
                # iterate through all children belonging to this node
                k = 0
                for pos ∈ rows[i-1][idx+1][1]:rows[i-1][idx+num_children][1]
                    if pos == rows[i-1][idx+k+1][1]
                        # reached location of the next child
                        k = k+1
                    end

                    conntype = if pos == rows[i-1][idx+1][1] && pos != col
                        # if this is the leftmost connected segment and its not above the parent, plot the left angle
                        :left
                    elseif pos == rows[i-1][idx+1][1] && pos == col
                        # if this is the leftmost connected segment and it is above the parent, plot the left angle
                        :left_down
                    elseif  pos == rows[i-1][idx+num_children][1] && pos != col
                        # if this is the rightmost connected segment and its not above the parent, plot the right angle
                        :right
                    elseif  pos == rows[i-1][idx+num_children][1] && pos == col
                        # if this is the rightmost connected segment and it is above the parent, plot the right angle with upward segment
                        :right_down
                    elseif  pos == rows[i-1][idx+k][1] && pos == col
                        # if this is below some child node and above the parent, plot the cross connector
                        :cross
                    elseif  pos == col
                        # if this is above the parent, plot the t connector
                        :t
                    elseif  pos == rows[i-1][idx+k][1]
                        # if this is below some child node, plot the inverted t connector
                        :inv_t
                    else
                        # if its neither of the above, it must be a horizontal spacer
                        :spacer
                    end
                    push!(objects, Connector(i, pos, conntype,cfg=cfg))
                end

                push!(objects, Label(i, rows[i-1][idx+num_children][1], node.threshold, :connector, cfg=cfg))
            end
            idx += num_children
            
            # add the segment itself
            seg = if num_children == 0 && i==length(rows)
                Segment(i,col, :singleton, cfg=cfg)
            elseif i==length(rows)
                Segment(i,col, :root, cfg=cfg)
            elseif num_children ==0
                Segment(i,col, :leaf, cfg=cfg)
            else
                Segment(i,col, :internal, cfg=cfg)
            end

            push!(objects, seg)

            if node.label != nothing
                # draw the label if the segment is labeled
                push!(objects, Label(i,col,node.label, :segment,cfg=cfg))
            end
        end
    end

    Scene(length(rows), num_columns, objects, cfg)
end