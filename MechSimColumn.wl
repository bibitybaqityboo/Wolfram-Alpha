(* ══════════════════════════════════════════════════════════════════
   MechSimColumn.wl — Column Buckling Module (Wolfram Language)
   Euler's formula + Johnson's parabola with animated mode shapes
   ══════════════════════════════════════════════════════════════════ *)

(* ── Material Database ── *)
columnMaterials = <|
  "Steel"     -> <|"E" -> 200*^9, "yieldStress" -> 250*^6, "color" -> RGBColor[0.53, 0.6, 0.67]|>,
  "Aluminum"  -> <|"E" -> 69*^9,  "yieldStress" -> 276*^6, "color" -> RGBColor[0.75, 0.82, 0.9]|>,
  "Titanium"  -> <|"E" -> 116*^9, "yieldStress" -> 880*^6, "color" -> RGBColor[0.56, 0.47, 0.78]|>,
  "Copper"    -> <|"E" -> 117*^9, "yieldStress" -> 70*^6,  "color" -> RGBColor[0.85, 0.55, 0.35]|>,
  "Cast Iron" -> <|"E" -> 170*^9, "yieldStress" -> 130*^6, "color" -> RGBColor[0.4, 0.4, 0.4]|>
|>;

(* ── End Condition K-factors ── *)
endConditions = <|
  "Pinned-Pinned" -> 1.0,
  "Fixed-Free"    -> 2.0,
  "Fixed-Pinned"  -> 0.7,
  "Fixed-Fixed"   -> 0.5
|>;

(* ── Moment of Inertia (rectangular cross-section, weaker axis) ── *)
calcColumnI[w_, d_] := Module[{Ix, Iy},
  Ix = w * d^3 / 12;
  Iy = d * w^3 / 12;
  Min[Ix, Iy]
];

(* ── Buckling Calculations ── *)
calcBuckling[material_, endCond_, L_, w_, d_, P_, mode_] :=
  Module[{mat, EE, sigmaY, Ival, A, K, Le, rg, slenderness, slendernessTransition,
          PcrEuler, Pcr, safety, isJohnson},

    mat = columnMaterials[material];
    EE = mat["E"];
    sigmaY = mat["yieldStress"];
    Ival = calcColumnI[w, d];
    A = w * d;
    K = endConditions[endCond];
    Le = K * L;
    rg = Sqrt[Ival / A];
    slenderness = Le / rg;
    slendernessTransition = Sqrt[2 Pi^2 EE / sigmaY];

    PcrEuler = mode^2 * Pi^2 * EE * Ival / Le^2;

    If[slenderness >= slendernessTransition || mode > 1,
      Pcr = PcrEuler; isJohnson = False,
      Pcr = sigmaY * A * (1 - (sigmaY * slenderness^2) / (4 Pi^2 EE));
      isJohnson = True
    ];

    safety = If[P > 0, Pcr / P, Infinity];

    <|"Pcr" -> Pcr, "PcrEuler" -> PcrEuler, "safety" -> safety,
      "slenderness" -> slenderness, "Le" -> Le, "K" -> K,
      "isJohnson" -> isJohnson, "rg" -> rg|>
  ];

(* ── Buckling Mode Shape ── *)
modeShape[yNorm_, endCond_, mode_, amplitude_] :=
  Switch[endCond,
    "Pinned-Pinned", amplitude * Sin[mode * Pi * yNorm],
    "Fixed-Free", amplitude * (1 - Cos[mode * Pi * yNorm / 2]),
    "Fixed-Pinned", Module[{beta = 4.4934 * mode, phi, phiMax = 0.637},
      phi = Sin[beta * yNorm] - (Sin[beta] / beta) * (beta * yNorm);
      amplitude * phi / phiMax
    ],
    "Fixed-Fixed", amplitude * (1 - Cos[2 mode * Pi * yNorm]) / 2,
    _, 0
  ];

(* ══════════════════════════════════════════════════════════════════
   3D Column Visualization
   ══════════════════════════════════════════════════════════════════ *)

column3D[L_, w_, d_, endCond_, mode_, P_, Pcr_, safety_] :=
  Module[{nSegs = 50, isBuckling, amplitude, colColor},

    isBuckling = P >= Pcr && P > 0;
    amplitude = If[isBuckling,
      Clip[(P / Pcr - 1) * 0.3, {0, 0.5}] + 0.1,
      0.02
    ];

    colColor = If[isBuckling, Red,
      If[safety < 2, Orange,
        RGBColor[0.53, 0.6, 0.67]]];

    Graphics3D[{
      EdgeForm[None],

      (* Deformed column segments *)
      Table[
        Module[{yNorm1 = i / nSegs, yNorm2 = (i + 1) / nSegs,
                dx1, dx2, y1, y2},
          y1 = yNorm1 * L;
          y2 = yNorm2 * L;
          dx1 = modeShape[yNorm1, endCond, mode, amplitude];
          dx2 = modeShape[yNorm2, endCond, mode, amplitude];
          {colColor, Cuboid[
            {dx1 - w * 2, y1, -d * 2},
            {dx2 + w * 2, y2, d * 2}
          ]}
        ],
        {i, 0, nSegs - 1}
      ],

      (* Bottom plate *)
      {Darker[Gray], Cuboid[{-0.25, -0.03, -0.25}, {0.25, 0, 0.25}]},

      (* Top plate *)
      {Darker[Gray], Cuboid[{-0.25, L, -0.25}, {0.25, L + 0.03, 0.25}]},

      (* Load arrow *)
      If[P > 0,
        {Red, Thick, Arrowheads[0.03],
         Arrow[{{0, L + 0.5, 0}, {0, L + 0.05, 0}}]},
        Nothing],

      (* Buckling warning text *)
      If[isBuckling,
        Text[Style["BUCKLED!", 16, Red, Bold], {0.5, L / 2, 0}],
        Nothing]
    },
      Boxed -> False, Lighting -> "Neutral",
      ViewPoint -> {2.5, 1.5, 1.5},
      ImageSize -> 400,
      PlotRange -> All
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimColumn[] := Manipulate[
  Module[{res},

    res = calcBuckling[material, endCond, colLength, colWidth / 1000, colDepth / 1000, load, mode];

    Column[{
      (* Results *)
      Panel[Grid[{
        {"Critical Load P_cr", NumberForm[res["Pcr"] / 1000, 5] <> " kN"},
        {"Safety Factor", Style[
          If[res["safety"] == Infinity, "\[Infinity]", NumberForm[res["safety"], 3]],
          If[res["safety"] >= 2, Darker[Green], If[res["safety"] >= 1, Orange, Red]]]},
        {"Slenderness Ratio", NumberForm[res["slenderness"], 4]},
        {"Effective Length", NumberForm[res["Le"], 3] <> " m"},
        {"Analysis Method", If[res["isJohnson"], "Johnson's Parabola", "Euler's Formula"]},
        {"K Factor", ToString[res["K"]]}
      }, Alignment -> Left, Spacings -> {2, 0.5}],
        "Column Buckling Results", Background -> LightOrange],

      (* 3D Column *)
      column3D[colLength, colWidth / 1000, colDepth / 1000,
        endCond, mode, load, res["Pcr"], res["safety"]],

      (* Mode Shape Plot *)
      Plot[
        modeShape[y / colLength, endCond, mode, 1],
        {y, 0, colLength},
        PlotLabel -> "Buckling Mode Shape (n = " <> ToString[mode] <> ")",
        AxesLabel -> {"Height (m)", "Lateral Deflection"},
        PlotStyle -> {Thick, If[load >= res["Pcr"], Red, Blue]},
        Filling -> Axis,
        ImageSize -> 400
      ]
    }, Spacings -> 1]
  ],

  {{material, "Steel", "Material"}, Keys[columnMaterials]},
  {{endCond, "Pinned-Pinned", "End Condition"},
    {"Pinned-Pinned", "Fixed-Free", "Fixed-Pinned", "Fixed-Fixed"}},
  Delimiter,
  {{colLength, 3.0, "Length (m)"}, 0.5, 10, 0.1, Appearance -> "Labeled"},
  {{colWidth, 50, "Width (mm)"}, 10, 300, 1, Appearance -> "Labeled"},
  {{colDepth, 50, "Depth (mm)"}, 10, 300, 1, Appearance -> "Labeled"},
  {{load, 50000, "Applied Load (N)"}, 0, 500000, 100, Appearance -> "Labeled"},
  {{mode, 1, "Buckling Mode"}, 1, 5, 1, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {material, endCond, colLength, colWidth, colDepth, load, mode}
]

(* Run: MechSimColumn[] *)
