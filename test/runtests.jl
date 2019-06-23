using PlotTree, Test

tree1 = Node([
    Node([
        Node("A"),
        Node("B"),
        Node("C"),
        Node("D"),
        Node("E")
    ], 3, "G"),
    Node([
        Node([
            Node([Node("a"),Node("b")],0,"X"),
            Node([Node("c")],1,"Y"),
        ],0,"F")
    ], 1, "H")
], 1, "I")

tree2 = Node("X")

eqn = repr("text/latex", tree1)

@test_throws AssertionError Scene(tree1, TreePlotCfg(
        segment_height=10,
        segment_width=10,
        text_width=20,
        connector_height=5,
        segment_color="red",
        connector_color="green",
        label_color="blue",
        threshold_color="orange",
        stroke_color="purple",
        # stroke_width=4,
        font_size=10
    )
)
#display("image/svg+xml", Scene(tree))

save("test1.svg", tree1)
save("test2.svg", tree2; scale_mm=5, text_width=5)
save("test3.svg", tree1;
    scale_mm =3,
    segment_height=10,
    segment_width=10,
    text_width=20,
    connector_height=10,
    segment_color="red",
    connector_color="green",
    label_color="blue",
    threshold_color="orange",
    stroke_color="purple",
    stroke_width=4,
    font_size=10
)

save("test4.svg", tree1; style=:equation)