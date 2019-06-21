import Base: show

function show(io, m::MIME"image/svg+xml", s::Scene)
    total_height = s.num_rows*(s.cfg.segment_height + s.cfg.connector_height) + 5*s.cfg.connector_height
    total_width = s.num_columns*(s.cfg.segment_width + 2*s.cfg.text_width) + 2*s.cfg.text_width
    c=join(map(x->repr(m,x), sort(s.objects,
        by=x-> if isa(x,Segment)
            2
        elseif isa(x,Label)
            3
        else
            1
        end)),"\n")
    txt = """
    <svg xmlns="http://www.w3.org/2000/svg"
        height="$(total_height*s.cfg.scale_mm)mm"
        width="$(total_width*s.cfg.scale_mm)mm"
        viewBox="0 0 $(total_width) $(total_height)">
        $(c)
    </svg>"""
    println(io,txt)
end

function show(io, ::MIME"image/svg+xml", s::Segment)
    txt="""
    <rect
        height="$(s.cfg.segment_height)" 
        width="$(s.cfg.segment_width)" 
        style="
            opacity: 1;
            fill:$(s.cfg.segment_color); 
            stroke:$(s.cfg.stroke_color);
            stroke-width:$(s.cfg.stroke_width);
            paint-order:markers fill stroke" 

        x = "$(get_column_offset(s.cfg, s.column) + s.cfg.text_width)"
        y = "$(get_row_offset(s.cfg, s.row) + s.cfg.connector_height)"
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:root})
    scales = [ c.cfg.segment_width/3;c.cfg.connector_height/5]
 
    curve1 = scales.*[0 1.093433;-3.000088 3.301732;-3.000075 3.848432;1.8e-5 0.546711;3.429367 0.962483;3.429367 0.962483;0 0;0.75892 0.05264;0.41968 0.547178;-0.339238 0.494546;-0.956631 0.972537;-2.356685 0.972537;-1.252243 0;-2.757767 0.570932;-3.995708 1.125417;-1.237941 0.554507;-2.191422 1.108714;-2.191422 1.108714]'
    curve2 = scales.*[0 0; 0.928602 -0.53917; 2.131732 -1.078082; 1.203123 -0.538897; 2.697702 -1.0609; 3.681609 -1.0609; 1.600055 0; 2.482624 -0.615842; 2.893417 -1.214703; 0.410797 -0.598866; 1.170046 -0.738044; 1.170046 -0.738044; 0 0; 3.44434 -0.420069; 3.444408 -0.96677; 6.9e-5 -0.546752; -2.99984 -2.755049; -3.000079 -3.848483]'
    c1 = join(map(i->join(curve1[:,i],","), 1:size(curve1,2)), " ")
    c2 = join(map(i->join(curve2[:,i],","), 1:size(curve2,2)), " ")
 
    v = join(scales.*[0.373789, 0.34218], ",")
    txt = """
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke"

        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width + c.cfg.segment_width) $(get_row_offset(c.cfg, c.row))
            h -$(c.cfg.segment_width)
            v $(c.cfg.segment_width)
            c $(c1) 
            l $(v) 
            c $(c2)
            v -$(c.cfg.segment_width)
            z"
    />
    """
    println(io, txt)
end


function show(io, ::MIME"image/svg+xml", l::Label{:segment})
    txt="""
    <text 
        style="
            font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:$(l.cfg.font_size);
            font-family:'Bitstream Charter'; font-variant-ligatures:normal; font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;
            letter-spacing:0px;word-spacing:0px;writing-mode:lr-tb;fill:$(l.cfg.label_color);fill-opacity:1;stroke:none;
            line-height:1.25;
            " 
        x="$(get_column_offset(l.cfg, l.column)-l.cfg.text_width*0.1)" 
        y="$(get_row_offset(l.cfg, l.row)+l.cfg.connector_height+l.cfg.segment_height/2)"
        dy="$(0.25*l.cfg.font_size)"
    >        
        <tspan>$(l.text)</tspan>
    </text>
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", l::Label{:connector})
    txt="""
    <text 
        style="
            font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:$(l.cfg.font_size);
            font-family:'Bitstream Charter'; font-variant-ligatures:normal; font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;
            letter-spacing:0px;word-spacing:0px;writing-mode:lr-tb;fill:$(l.cfg.threshold_color);fill-opacity:1;stroke:none;
            line-height:1.25;
            " 
        x="$(get_column_offset(l.cfg, l.column)+l.cfg.segment_width+l.cfg.text_width*1.1)" 
        y="$(get_row_offset(l.cfg, l.row)+l.cfg.connector_height/2)"
        dy="$(0.25*l.cfg.font_size)"
    >        
        <tspan>$(l.text)</tspan>
    </text>
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:cap})
    txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d=" 
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width + c.cfg.segment_width) $(get_row_offset(c.cfg, c.row) + c.cfg.connector_height)
            a $(c.cfg.segment_width/2) $(c.cfg.segment_width/2), 0, 0, 0, -$(c.cfg.segment_width) 0
            Z
        "
    />
    """
println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:up})
    txt="""
    <rect
        height="$(c.cfg.connector_height)" 
        width="$(c.cfg.segment_width)" 
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        x="$(get_column_offset(c.cfg, c.column) + c.cfg.text_width)"
        y="$(get_row_offset(c.cfg, c.row))"
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:spacer})
    txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column)) $(get_row_offset(c.cfg, c.row)+(c.cfg.connector_height - c.cfg.segment_width)/2)
            h $(c.cfg.segment_width+2c.cfg.text_width+0.1*c.cfg.segment_width)
            v $(c.cfg.segment_width)
            h -$(c.cfg.segment_width+2c.cfg.text_width+0.1*c.cfg.segment_width)
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column)) $(get_row_offset(c.cfg, c.row)+(c.cfg.connector_height - c.cfg.segment_width)/2)
            h $(c.cfg.segment_width+2c.cfg.text_width+0.1*c.cfg.segment_width)
            m 0 $(c.cfg.segment_width)
            h -$(c.cfg.segment_width+2c.cfg.text_width+0.1*c.cfg.segment_width)
            "
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:left})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            a $(r_large),$(r_large) 0 0 0 $(r_large),$(r_large) 
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            v -$(c.cfg.segment_width) 
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 1 -$(r_small),-$(r_small) 
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            a $(r_large),$(r_large) 0 0 0 $(r_large),$(r_large) 
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            m 0 -$(c.cfg.segment_width) 
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 1 -$(r_small),-$(r_small) 
            "
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:right})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.segment_width + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            a $(r_large),$(r_large) 0 0 1 -$(r_large),$(r_large) 
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            v -$(c.cfg.segment_width) 
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small) 
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.segment_width + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            a $(r_large),$(r_large) 0 0 1 -$(r_large),$(r_large) 
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            m 0 -$(c.cfg.segment_width) 
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small) 
            "
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:right_down})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            h $(c.cfg.segment_width)
            v $(c.cfg.connector_height)
            h -$(c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 0 -$(r_small),-$(r_small)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            v -$(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small)
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            h $(c.cfg.segment_width)
            v $(c.cfg.connector_height)
            h -$(c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 0 -$(r_small),-$(r_small)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            m 0 -$(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small)
            "
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:left_down})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width + c.cfg.segment_width) $(get_row_offset(c.cfg, c.row))
            h -$(c.cfg.segment_width)
            v $(c.cfg.connector_height)
            h $(c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 1 $(r_small),-$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            v -$(c.cfg.segment_width)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 1 -$(r_small),-$(r_small)
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width + c.cfg.segment_width) $(get_row_offset(c.cfg, c.row))
            h -$(c.cfg.segment_width)
            v $(c.cfg.connector_height)
            h $(c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 1 $(r_small),-$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            m 0 -$(c.cfg.segment_width)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 1 -$(r_small),-$(r_small)
            "
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:cross})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            h $(c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            v $(c.cfg.segment_width)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 -$(r_small),$(r_small)
            h -$(c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 0 -$(r_small),-$(r_small)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            v -$(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small)
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            h $(c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            m 0 $(c.cfg.segment_width)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 -$(r_small),$(r_small)
            h -$(c.cfg.segment_width) 
            a $(r_small),$(r_small) 0 0 0 -$(r_small),-$(r_small)
            h -$(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            m 0 -$(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small)
            "
    />
    """
    println(io, txt)
end

function show(io, ::MIME"image/svg+xml", c::Connector{:t})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row)+c.cfg.connector_height)
            h $(c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 1 $(r_small),-$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            v -$(c.cfg.segment_width)
            h -$(2*c.cfg.text_width+c.cfg.segment_width+0.2*c.cfg.segment_width)
            v $(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 1 $(r_small),$(r_small)
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row)+c.cfg.connector_height)
            h $(c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 1 $(r_small),-$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            m 0 -$(c.cfg.segment_width)
            h -$(2*c.cfg.text_width+c.cfg.segment_width+0.2*c.cfg.segment_width)
            m 0 $(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 1 $(r_small),$(r_small)
            "
    />
    """
    println(io, txt)
end


function show(io, ::MIME"image/svg+xml", c::Connector{:inv_t})
    r_small = (c.cfg.connector_height - c.cfg.segment_width)/2
    r_large = c.cfg.segment_width + r_small
txt="""
    <path
        style="
            opacity:1;
            fill:$(c.cfg.connector_color);
            stroke:none;
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            h $(c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            v $(c.cfg.segment_width)
            h -$(2*c.cfg.text_width+c.cfg.segment_width+0.2*c.cfg.segment_width)
            v -$(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small)
            Z"
    />
    <path
        style="
            opacity:1;
            fill:none;
            stroke:$(c.cfg.stroke_color);
            stroke-width:$(c.cfg.stroke_width);
            paint-order:markers fill stroke" 
        d="
            M $(get_column_offset(c.cfg, c.column) + c.cfg.text_width) $(get_row_offset(c.cfg, c.row))
            h $(c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),$(r_small)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            m 0 $(c.cfg.segment_width)
            h -$(2*c.cfg.text_width+c.cfg.segment_width+0.2*c.cfg.segment_width)
            m 0 -$(c.cfg.segment_width)
            h $(c.cfg.text_width-r_small+0.1*c.cfg.segment_width)
            a $(r_small),$(r_small) 0 0 0 $(r_small),-$(r_small)
            "
    />
    """
    println(io, txt)
end

save(f::String, s::Scene) = open(f, "w") do h
    if endswith(f, ".svg")
        show(h, "image/svg+xml", s)
    else
       throw(NotImplementedError("Saving Scene objects is only supported for svg files at the moment."))
    end
end
