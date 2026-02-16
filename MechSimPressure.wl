(* ══════════════════════════════════════════════════════════════════
   MechSimPressure.wl — Pressure Vessel Module (Wolfram Language)
   Thin/thick-walled cylinder and sphere analysis
   ══════════════════════════════════════════════════════════════════ *)

(* ── Material Database ── *)
pressureMaterials = <|
  "Steel"     -> <|"yieldStress" -> 250*^6|>,
  "Aluminum"  -> <|"yieldStress" -> 276*^6|>,
  "Titanium"  -> <|"yieldStress" -> 880*^6|>,
  "Copper"    -> <|"yieldStress" -> 70*^6|>,
  "Cast Iron" -> <|"yieldStress" -> 130*^6|>
|>;

(* ── Stress Calculations ── *)
calcPressureVessel[shape_, material_, ri_, t_, pi_, po_] :=
  Module[{ro, yieldS, hoopStress, longStress, radialStress, vmStress, safety, rtRatio, isThin},

    ro = ri + t;
    yieldS = pressureMaterials[material]["yieldStress"];
    isThin = ri / t > 10;
    rtRatio = ri / t;

    If[isThin,
      (* Thin-walled approximation *)
      Module[{pNet = pi - po},
        If[shape == "Cylinder",
          hoopStress = pNet * ri / t;
          longStress = pNet * ri / (2 t),
          (* Sphere *)
          hoopStress = pNet * ri / (2 t);
          longStress = hoopStress
        ];
        radialStress = -pi;
      ],
      (* Thick-walled: Lamé equations at inner surface *)
      Module[{k = ro / ri, k2},
        If[shape == "Cylinder",
          k2 = k^2;
          hoopStress = (pi (k2 + 1) - po * 2 k2) / (k2 - 1);
          longStress = (pi - po k2) / (k2 - 1);
          radialStress = -pi,
          (* Thick sphere *)
          Module[{ri3 = ri^3, ro3 = ro^3, denom},
            denom = 2 (ro3 - ri3);
            hoopStress = pi (ro3 + 2 ri3) / denom - po * 2 ro3 / denom;
            longStress = hoopStress;
            radialStress = -pi
          ]
        ]
      ]
    ];

    (* Von Mises *)
    vmStress = Sqrt[0.5 ((hoopStress - longStress)^2 +
                         (longStress - radialStress)^2 +
                         (radialStress - hoopStress)^2)];
    safety = If[vmStress > 0, yieldS / vmStress, Infinity];

    <|"hoop" -> hoopStress, "long" -> longStress, "radial" -> radialStress,
      "vonMises" -> vmStress, "safety" -> safety, "rtRatio" -> rtRatio,
      "isThin" -> isThin|>
  ];

(* ── Stress Heatmap Color ── *)
heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

(* ══════════════════════════════════════════════════════════════════
   3D Vessel Visualization with Cutaway
   ══════════════════════════════════════════════════════════════════ *)

vesselCutaway3D[shape_, ri_, t_, vesselLength_, stressRatio_, cutaway_] :=
  Module[{ro = ri + t, col, phiLen},

    col = heatmapColor[Clip[stressRatio, {0, 1}]];
    phiLen = If[cutaway, 3 Pi / 2, 2 Pi];

    If[shape == "Cylinder",
      (* Cylinder cutaway *)
      Show[
        (* Outer shell *)
        ParametricPlot3D[
          {ro Cos[theta], ro Sin[theta], z},
          {theta, 0, phiLen}, {z, 0, vesselLength},
          PlotStyle -> {col, Opacity[0.7]},
          Mesh -> None, BoundaryStyle -> Gray
        ],
        (* Inner shell (visible in cutaway) *)
        If[cutaway,
          ParametricPlot3D[
            {ri Cos[theta], ri Sin[theta], z},
            {theta, 0, phiLen}, {z, 0, vesselLength},
            PlotStyle -> {Darker[Gray, 0.3], Opacity[0.5]},
            Mesh -> None
          ],
          Graphics3D[{}]
        ],
        (* Top and bottom cap rings *)
        If[cutaway,
          Graphics3D[{col, Opacity[0.8],
            (* Top ring *)
            Table[Polygon[{
              {ri Cos[th], ri Sin[th], vesselLength},
              {ro Cos[th], ro Sin[th], vesselLength},
              {ro Cos[th + 0.1], ro Sin[th + 0.1], vesselLength},
              {ri Cos[th + 0.1], ri Sin[th + 0.1], vesselLength}
            }], {th, 0, phiLen - 0.1, 0.1}],
            (* Bottom ring *)
            Table[Polygon[{
              {ri Cos[th], ri Sin[th], 0},
              {ro Cos[th], ro Sin[th], 0},
              {ro Cos[th + 0.1], ro Sin[th + 0.1], 0},
              {ri Cos[th + 0.1], ri Sin[th + 0.1], 0}
            }], {th, 0, phiLen - 0.1, 0.1}]
          }],
          Graphics3D[{}]
        ],
        Boxed -> False, Lighting -> "Neutral",
        ViewPoint -> {2.5, 1.5, 1.5},
        ImageSize -> 450, PlotRange -> All, Axes -> False
      ],

      (* Sphere cutaway *)
      Show[
        ParametricPlot3D[
          {ro Sin[phi] Cos[theta], ro Sin[phi] Sin[theta], ro Cos[phi]},
          {theta, 0, phiLen}, {phi, 0, Pi},
          PlotStyle -> {col, Opacity[0.7]},
          Mesh -> None, BoundaryStyle -> Gray
        ],
        If[cutaway,
          ParametricPlot3D[
            {ri Sin[phi] Cos[theta], ri Sin[phi] Sin[theta], ri Cos[phi]},
            {theta, 0, phiLen}, {phi, 0, Pi},
            PlotStyle -> {Darker[Gray, 0.3], Opacity[0.5]},
            Mesh -> None
          ],
          Graphics3D[{}]
        ],
        Boxed -> False, Lighting -> "Neutral",
        ViewPoint -> {2.5, 1.5, 1.5},
        ImageSize -> 450, PlotRange -> All, Axes -> False
      ]
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   Radial Stress Distribution (Thick-Walled Only)
   ══════════════════════════════════════════════════════════════════ *)

radialStressPlot[ri_, t_, pi_, po_] := Module[{ro = ri + t, k2},
  k2 = (ro / ri)^2;
  Plot[
    {(* Hoop *) (pi * ri^2 - po * ro^2) / (ro^2 - ri^2) + ri^2 ro^2 (pi - po) / ((ro^2 - ri^2) r^2),
     (* Radial *) (pi * ri^2 - po * ro^2) / (ro^2 - ri^2) - ri^2 ro^2 (pi - po) / ((ro^2 - ri^2) r^2)},
    {r, ri, ro},
    PlotLabel -> "Stress Distribution Through Wall",
    AxesLabel -> {"Radius (m)", "Stress (Pa)"},
    PlotLegends -> {"Hoop (\[Sigma]_\[Theta])", "Radial (\[Sigma]_r)"},
    PlotStyle -> {{Thick, Red}, {Thick, Blue}},
    Filling -> Axis,
    ImageSize -> 450
  ]
];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimPressure[] := Manipulate[
  Module[{res, stressRatio, yieldS},

    res = calcPressureVessel[shape, material, radius / 1000, thickness / 1000,
            intPressure * 1*^6, extPressure * 1*^6];
    yieldS = pressureMaterials[material]["yieldStress"];
    stressRatio = Clip[res["vonMises"] / yieldS, {0, 1}];

    Column[{
      (* Results *)
      Panel[Grid[{
        {"Hoop Stress", NumberForm[res["hoop"] / 1*^6, 4] <> " MPa"},
        {"Longitudinal Stress", NumberForm[res["long"] / 1*^6, 4] <> " MPa"},
        {"Radial Stress", NumberForm[res["radial"] / 1*^6, 4] <> " MPa"},
        {"Von Mises Stress", NumberForm[res["vonMises"] / 1*^6, 4] <> " MPa"},
        {"r/t Ratio", NumberForm[res["rtRatio"], 4]},
        {"Analysis", If[res["isThin"], "Thin-walled (r/t > 10)", "Thick-walled (Lam\[EAcute])"]},
        {"Safety Factor", Style[
          If[res["safety"] == Infinity, "\[Infinity]", NumberForm[res["safety"], 3]],
          If[res["safety"] >= 2, Darker[Green], If[res["safety"] >= 1, Orange, Red]]]}
      }, Alignment -> Left, Spacings -> {2, 0.5}],
        "Pressure Vessel Results", Background -> LightGreen],

      (* 3D Vessel *)
      vesselCutaway3D[shape, radius / 1000, thickness / 1000,
        vesselLength, stressRatio, cutaway],

      (* Stress distribution for thick-walled *)
      If[!res["isThin"],
        radialStressPlot[radius / 1000, thickness / 1000,
          intPressure * 1*^6, extPressure * 1*^6],
        Style["Thin-walled analysis — uniform stress assumed through thickness.",
          12, Gray, Italic]
      ]
    }, Spacings -> 1]
  ],

  {{shape, "Cylinder", "Vessel Shape"}, {"Cylinder", "Sphere"}},
  {{material, "Steel", "Material"}, Keys[pressureMaterials]},
  Delimiter,
  {{radius, 500, "Inner Radius (mm)"}, 50, 2000, 10, Appearance -> "Labeled"},
  {{thickness, 10, "Wall Thickness (mm)"}, 1, 200, 1, Appearance -> "Labeled"},
  {{vesselLength, 2.0, "Length (m) — Cylinder only"}, 0.5, 5.0, 0.1, Appearance -> "Labeled"},
  {{intPressure, 5.0, "Internal Pressure (MPa)"}, 0, 50, 0.1, Appearance -> "Labeled"},
  {{extPressure, 0.0, "External Pressure (MPa)"}, 0, 20, 0.1, Appearance -> "Labeled"},
  {{cutaway, True, "Cutaway View"}, {True, False}},
  ControlPlacement -> Left,
  TrackedSymbols :> {shape, material, radius, thickness, vesselLength, intPressure, extPressure, cutaway}
]

(* Run: MechSimPressure[] *)
