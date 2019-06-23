function Base.show(io, m::MIME"text/latex", node::Node; max_summands=4, sets=[], root=true)
    function wrap_if_necessary(n::Node, sets) 
        bio = IOBuffer()
        show(bio, m, n; max_summands=max_summands, sets=sets, root=false)
        res = String(take!(bio))
        if isempty(n.children) && n.threshold == 0
            res
        else
            "\\left($(res)\\right)"
        end
    end

    str = if length(node.children) == 0 && node.threshold == 0
        "{$(node.label)}"
    elseif length(node.children) == 0
        "\\emptyset \\rightarrow_{$(node.threshold)} {$(node.label)}"
    elseif length(node.children) ≤ max_summands
        lhs = join(map(c->wrap_if_necessary(c,sets), node.children), "+")
        "$(lhs) \\rightarrow_{$(node.threshold)} {$(node.label)}"
    else
        push!(sets,join(map(c->wrap_if_necessary(c,sets), node.children), ","))
        "\\sum_{X\\in S_{$(length(sets))}} X \\rightarrow_{$(node.threshold)} {$(node.label)}"
    end

    str= if root && ~isempty(sets)
        whereblock = join(map(((i,s),)->"&S_{$(i)}:=\\{$(s)\\}", enumerate(sets)), "\\\\\n")
        "\\begin{align*}\n &$(str)\\\\\n \\text{where }$(whereblock)\n\\end{align*}"
    elseif root
        "\\[$(str)\\]"
    else 
        str
    end

    write(io, str)
end