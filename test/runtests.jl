using PlotTree, Test

tree = ([
    ([
        ([],0,"A"),
        ([],0,"B"),
        ([],0,"C"),
        ([],0,"D")
    ], 3, "F"),
    ([
        ([
            ([([],0,"a"),([],0,"b")],0,"X"),
            ([([],0,"c")],1,"Y"),
        ],0,"E")
    ], 1, "G")
], 1, "H")

s1 = Scene(tree)
s2 = Scene(tree, TreePlotCfg(scale_mm=5))
s3 = Scene(tree, TreePlotCfg(
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
)

@test_throws AssertionError s4 = Scene(tree, TreePlotCfg(
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

save("test1.svg", s1)
save("test2.svg", s2)
save("test3.svg", s3)
