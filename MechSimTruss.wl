(* ══════════════════════════════════════════════════════════════════
   MechSimTruss.wl — Truss Analysis Module (Wolfram Language)
   Direct Stiffness Method solver with template trusses
   ══════════════════════════════════════════════════════════════════ *)

(* ══════════════════════════════════════════════════════════════════
   Direct Stiffness Method Solver
   ══════════════════════════════════════════════════════════════════ *)

solveTruss[nodes_, members_, supports_, loads_, EE_: 200*^9, AA_: 0.001] :=
  Module[{nNodes, nDOF, K, F, dofs, ke, dx, dy, Lm, c, s, k, u, memberForces = {},
          penalty = 1*^20},

    nNodes = Length[nodes];
    nDOF = nNodes * 2;
    If[nDOF == 0, Return[<|"error" -> "No nodes"|>]];

    (* Initialize global stiffness matrix and force vector *)
    K = ConstantArray[0., {nDOF, nDOF}];
    F = ConstantArray[0., nDOF];

    (* Assemble global stiffness *)
    Do[
      Module[{a = m[[1]], b = m[[2]]},
        dx = nodes[[b, 1]] - nodes[[a, 1]];
        dy = nodes[[b, 2]] - nodes[[a, 2]];
        Lm = Sqrt[dx^2 + dy^2];
        If[Lm < 1*^-6, Continue[]];

        c = dx / Lm; s = dy / Lm;
        k = EE * AA / Lm;

        dofs = {2 a - 1, 2 a, 2 b - 1, 2 b};
        ke = k * {
          {c c, c s, -c c, -c s},
          {c s, s s, -c s, -s s},
          {-c c, -c s, c c, c s},
          {-c s, -s s, c s, s s}
        };

        Do[
          K[[dofs[[i]], dofs[[j]]]] += ke[[i, j]],
          {i, 4}, {j, 4}
        ];
      ],
      {m, members}
    ];

    (* Apply loads: each load is {nodeId, fx, fy} *)
    Do[
      F[[2 l[[1]] - 1]] += l[[2]];
      F[[2 l[[1]]]] += l[[3]],
      {l, loads}
    ];

    (* Apply boundary conditions via penalty method *)
    (* Each support is {nodeId, type} where type is "pin" or "roller" *)
    Do[
      Module[{dofX = 2 sup[[1]] - 1, dofY = 2 sup[[1]]},
        If[sup[[2]] == "pin",
          K[[dofX, dofX]] += penalty;
          K[[dofY, dofY]] += penalty
        ];
        If[sup[[2]] == "roller",
          K[[dofY, dofY]] += penalty
        ]
      ],
      {sup, supports}
    ];

    (* Solve *)
    u = Quiet[LinearSolve[K, F]];
    If[!ListQ[u], Return[<|"error" -> "Singular matrix"|>]];

    (* Calculate member forces *)
    Do[
      Module[{a = m[[1]], b = m[[2]], du, dv, force},
        dx = nodes[[b, 1]] - nodes[[a, 1]];
        dy = nodes[[b, 2]] - nodes[[a, 2]];
        Lm = Sqrt[dx^2 + dy^2];
        If[Lm < 1*^-6, AppendTo[memberForces, 0]; Continue[]];

        c = dx / Lm; s = dy / Lm;
        du = u[[2 b - 1]] - u[[2 a - 1]];
        dv = u[[2 b]] - u[[2 a]];
        force = (EE * AA / Lm) * (c du + s dv);
        AppendTo[memberForces, force]
      ],
      {m, members}
    ];

    <|"displacements" -> u, "memberForces" -> memberForces|>
  ];

(* ══════════════════════════════════════════════════════════════════
   Template Trusses (Pratt, Warren, Howe, K-Truss)
   ══════════════════════════════════════════════════════════════════ *)

trussTemplate[name_, nBays_: 4, bayWidth_: 2.0, trussHeight_: 2.0] :=
  Module[{nodes = {}, members = {}, supports = {}, loads = {},
          n = nBays, w = bayWidth, h = trussHeight},

    Switch[name,
      "Pratt",
        (* Bottom chord nodes *)
        Do[AppendTo[nodes, {i * w, 0}], {i, 0, n}];
        (* Top chord nodes *)
        Do[AppendTo[nodes, {i * w, h}], {i, 0, n}];
        (* Bottom chord members *)
        Do[AppendTo[members, {i, i + 1}], {i, 1, n}];
        (* Top chord members *)
        Do[AppendTo[members, {n + 1 + i, n + 2 + i}], {i, 0, n - 1}];
        (* Verticals *)
        Do[AppendTo[members, {i, n + 1 + i}], {i, 1, n + 1}];
        (* Diagonals — Pratt pattern: tension diags go from bottom-outer to top-inner *)
        Do[AppendTo[members, {i, n + 2 + i}], {i, 1, n}]; (* bottom-left to top-right *)

        supports = {{1, "pin"}, {n + 1, "roller"}};
        loads = Table[{n + 1 + i, 0, -10000}, {i, 1, n}], (* loads on top chord *)

      "Warren",
        Do[AppendTo[nodes, {i * w, 0}], {i, 0, n}];
        Do[AppendTo[nodes, {(i - 0.5) * w, h}], {i, 1, n}];
        (* Bottom chord *)
        Do[AppendTo[members, {i, i + 1}], {i, 1, n}];
        (* Top chord *)
        If[n > 1, Do[AppendTo[members, {n + 1 + i, n + 2 + i}], {i, 0, n - 2}]];
        (* Diagonals: each bottom node connects to adjacent top nodes *)
        Do[
          AppendTo[members, {i, n + i}];        (* left diag *)
          AppendTo[members, {i + 1, n + i}],    (* right diag *)
          {i, 1, n}
        ];

        supports = {{1, "pin"}, {n + 1, "roller"}};
        loads = Table[{n + 1 + i, 0, -10000}, {i, 0, n - 1}],

      "Howe",
        Do[AppendTo[nodes, {i * w, 0}], {i, 0, n}];
        Do[AppendTo[nodes, {i * w, h}], {i, 0, n}];
        Do[AppendTo[members, {i, i + 1}], {i, 1, n}];
        Do[AppendTo[members, {n + 1 + i, n + 2 + i}], {i, 0, n - 1}];
        Do[AppendTo[members, {i, n + 1 + i}], {i, 1, n + 1}];
        (* Diagonals — Howe: compression diags from top-outer to bottom-inner *)
        Do[AppendTo[members, {i + 1, n + i}], {i, 1, n}]; (* reverse of Pratt *)

        supports = {{1, "pin"}, {n + 1, "roller"}};
        loads = Table[{n + 1 + i, 0, -10000}, {i, 1, n}],

      "K-Truss",
        Do[AppendTo[nodes, {i * w, 0}], {i, 0, n}];
        Do[AppendTo[nodes, {i * w, h}], {i, 0, n}];
        Do[AppendTo[nodes, {i * w, h / 2}], {i, 0, n}]; (* mid-height *)
        Do[AppendTo[members, {i, i + 1}], {i, 1, n}];
        Do[AppendTo[members, {n + 1 + i, n + 2 + i}], {i, 0, n - 1}];
        Do[AppendTo[members, {i, 2 n + 2 + i}], {i, 1, n + 1}]; (* bottom to mid *)
        Do[AppendTo[members, {2 n + 2 + i, n + 1 + i}], {i, 0, n}]; (* mid to top *)
        (* K diagonals *)
        Do[
          AppendTo[members, {2 n + 2 + i, i + 1}]; (* mid to bottom-right *)
          AppendTo[members, {2 n + 1 + i, n + 2 + i}], (* mid-left to top-right *)
          {i, 1, n}
        ];

        supports = {{1, "pin"}, {n + 1, "roller"}};
        loads = Table[{n + 1 + i, 0, -10000}, {i, 1, n}]
    ];

    <|"nodes" -> nodes, "members" -> members,
      "supports" -> supports, "loads" -> loads|>
  ];

(* ══════════════════════════════════════════════════════════════════
   Truss Visualization
   ══════════════════════════════════════════════════════════════════ *)

trussPlot[nodes_, members_, supports_, loads_, result_, deformScale_] :=
  Module[{graphics = {}, maxForce, disps, deformedNodes},

    If[KeyExistsQ[result, "error"],
      Return[Text[Style[result["error"], 16, Red]]]
    ];

    disps = result["displacements"];
    maxForce = Max[Abs /@ result["memberForces"], 0.001];

    (* Deformed nodes *)
    deformedNodes = Table[
      {nodes[[i, 1]] + disps[[2 i - 1]] * deformScale,
       nodes[[i, 2]] + disps[[2 i]] * deformScale},
      {i, Length[nodes]}
    ];

    Graphics[{
      (* Original members (gray ghost) *)
      {LightGray, Thin,
        Table[Line[{nodes[[m[[1]]]], nodes[[m[[2]]]]}], {m, members}]},

      (* Deformed members with force coloring *)
      Table[
        Module[{force = result["memberForces"][[i]],
                n1 = deformedNodes[[members[[i, 1]]]],
                n2 = deformedNodes[[members[[i, 2]]]],
                col, thick},
          col = If[force > 0,
            Blend[{White, Blue}, Clip[force / maxForce, {0, 1}]],
            Blend[{White, Red}, Clip[-force / maxForce, {0, 1}]]
          ];
          thick = Clip[Abs[force] / maxForce * 4, {1, 5}];
          {col, Thickness[thick * 0.003], Line[{n1, n2}]}
        ],
        {i, Length[members]}
      ],

      (* Deformed nodes *)
      {Black, PointSize[Large],
        Point /@ deformedNodes},

      (* Node labels *)
      Table[
        Text[Style[ToString[i], 8, Gray],
          deformedNodes[[i]] + {0.15, 0.15}],
        {i, Length[nodes]}
      ],

      (* Supports *)
      Table[
        Module[{pos = deformedNodes[[sup[[1]]]]},
          If[sup[[2]] == "pin",
            {Darker[Green], PointSize[0.02], Point[pos],
             EdgeForm[Darker[Green]], FaceForm[None],
             Polygon[{pos + {-0.2, -0.3}, pos + {0.2, -0.3}, pos}]},
            {Orange, PointSize[0.02], Point[pos],
             EdgeForm[Orange], FaceForm[None],
             Polygon[{pos + {-0.2, -0.3}, pos + {0.2, -0.3}, pos}],
             Line[{pos + {-0.25, -0.35}, pos + {0.25, -0.35}}]}
          ]
        ],
        {sup, supports}
      ],

      (* Load arrows *)
      Table[
        Module[{pos = deformedNodes[[l[[1]]]], mag},
          mag = Sqrt[l[[2]]^2 + l[[3]]^2];
          {Red, Thick, Arrowheads[0.04],
           Arrow[{pos + Normalize[{l[[2]], l[[3]]}] * 0.8, pos}]}
        ],
        {l, loads}
      ],

      (* Force magnitude labels on members *)
      Table[
        Module[{n1 = deformedNodes[[members[[i, 1]]]],
                n2 = deformedNodes[[members[[i, 2]]]],
                force = result["memberForces"][[i]],
                midPt, label, col},
          midPt = (n1 + n2) / 2 + {0, 0.2};
          label = ToString[NumberForm[force / 1000, {4, 1}]] <> " kN";
          col = If[force > 0, Blue, Red];
          Text[Style[label, 7, col, Bold], midPt]
        ],
        {i, Length[members]}
      ],

      (* Force legend *)
      {Text[Style["Blue = Tension", 10, Blue], Scaled[{0.85, 0.95}]],
       Text[Style["Red = Compression", 10, Red], Scaled[{0.85, 0.90}]]}
    },
      Axes -> True, AxesLabel -> {"x (m)", "y (m)"},
      PlotLabel -> "Truss Analysis — Deformed Shape",
      ImageSize -> 600, AspectRatio -> Automatic,
      PlotRange -> All
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   Member Forces Bar Chart
   ══════════════════════════════════════════════════════════════════ *)

forceBarChart[memberForces_] :=
  BarChart[memberForces / 1000,
    ChartLabels -> Table["M" <> ToString[i], {i, Length[memberForces]}],
    ChartStyle -> Table[
      If[memberForces[[i]] > 0, Blue, Red],
      {i, Length[memberForces]}
    ],
    PlotLabel -> "Member Forces (kN)",
    AxesLabel -> {None, "Force (kN)"},
    ImageSize -> 600
  ];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimTruss[] := Manipulate[
  Module[{tmpl, result, maxDisp, maxForce},

    tmpl = trussTemplate[template, nBays, bayWidth, trussHeight];
    result = solveTruss[tmpl["nodes"], tmpl["members"],
               tmpl["supports"], tmpl["loads"]];

    If[KeyExistsQ[result, "error"],
      Style["Error: " <> result["error"], 16, Red],

      (* Success *)
      maxDisp = Max[Abs /@ result["displacements"]];
      maxForce = Max[Abs /@ result["memberForces"]];

      Column[{
        (* Results *)
        Panel[Grid[{
          {"Nodes", Length[tmpl["nodes"]]},
          {"Members", Length[tmpl["members"]]},
          {"Max Displacement", NumberForm[maxDisp * 1000, 4] <> " mm"},
          {"Max Member Force", NumberForm[maxForce / 1000, 4] <> " kN"}
        }, Alignment -> Left, Spacings -> {2, 0.5}],
          "Truss Analysis Results", Background -> LightBlue],

        (* Deformed shape *)
        trussPlot[tmpl["nodes"], tmpl["members"], tmpl["supports"],
          tmpl["loads"], result, deformScale],

        (* Force bar chart *)
        forceBarChart[result["memberForces"]]
      }, Spacings -> 1]
    ]
  ],

  {{template, "Pratt", "Truss Template"}, {"Pratt", "Warren", "Howe", "K-Truss"}},
  Delimiter,
  {{nBays, 4, "Number of Bays"}, 2, 10, 1, Appearance -> "Labeled"},
  {{bayWidth, 2.0, "Bay Width (m)"}, 1.0, 5.0, 0.5, Appearance -> "Labeled"},
  {{trussHeight, 2.0, "Truss Height (m)"}, 1.0, 5.0, 0.5, Appearance -> "Labeled"},
  {{deformScale, 500, "Deformation Scale"}, 1, 5000, 10, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {template, nBays, bayWidth, trussHeight, deformScale}
]

(* Run: MechSimTruss[] *)
