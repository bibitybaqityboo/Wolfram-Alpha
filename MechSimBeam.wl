(* ══════════════════════════════════════════════════════════════════
   MechSimBeam.wl — Beam Analysis Module (Wolfram Language)
   Simply Supported, Cantilever, Fixed-Fixed, Overhanging beams
   with point load, distributed load, and moment analysis.
   ══════════════════════════════════════════════════════════════════ *)

(* ── Material Database ── *)
materials = <|
  "Steel"     -> <|"E" -> 200*^9, "yieldStress" -> 250*^6, "color" -> RGBColor[0.53, 0.6, 0.67]|>,
  "Aluminum"  -> <|"E" -> 69*^9,  "yieldStress" -> 276*^6, "color" -> RGBColor[0.75, 0.82, 0.9]|>,
  "Titanium"  -> <|"E" -> 116*^9, "yieldStress" -> 880*^6, "color" -> RGBColor[0.56, 0.47, 0.78]|>,
  "Copper"    -> <|"E" -> 117*^9, "yieldStress" -> 70*^6,  "color" -> RGBColor[0.85, 0.55, 0.35]|>,
  "Concrete"  -> <|"E" -> 30*^9,  "yieldStress" -> 30*^6,  "color" -> RGBColor[0.5, 0.5, 0.5]|>,
  "Cast Iron" -> <|"E" -> 170*^9, "yieldStress" -> 130*^6, "color" -> RGBColor[0.4, 0.4, 0.4]|>
|>;

(* ── Cross-Section Moment of Inertia ── *)
calcI[width_, height_] := width * height^3 / 12;

(* ══════════════════════════════════════════════════════════════════
   Beam Deflection, Moment, and Shear Functions
   ══════════════════════════════════════════════════════════════════ *)

(* --- Simply Supported Beam with Point Load at position a --- *)
ssPointDeflection[x_, P_, a_, L_, EI_] := Module[{b = L - a},
  Piecewise[{
    {-(P b x) / (6 EI L) (L^2 - b^2 - x^2), 0 <= x <= a},
    {-(P a (L - x)) / (6 EI L) (2 L x - a^2 - x^2), a < x <= L}
  }, 0]
];

ssPointMoment[x_, P_, a_, L_] := Module[{b = L - a},
  Piecewise[{
    {P b x / L, 0 <= x <= a},
    {P a (L - x) / L, a < x <= L}
  }, 0]
];

ssPointShear[x_, P_, a_, L_] := Module[{b = L - a},
  Piecewise[{
    {P b / L, 0 <= x < a},
    {-P a / L, a <= x <= L}
  }, 0]
];

(* --- Cantilever Beam with Point Load at tip --- *)
cantPointDeflection[x_, P_, L_, EI_] :=
  -(P / (6 EI)) (3 L x^2 - x^3);

cantPointMoment[x_, P_, L_] :=
  -P (L - x);

cantPointShear[x_, P_, L_] := P;

(* --- Simply Supported with Distributed Load --- *)
ssDistDeflection[x_, w_, L_, EI_] :=
  -(w x) / (24 EI) (L^3 - 2 L x^2 + x^3);

ssDistMoment[x_, w_, L_] :=
  w x (L - x) / 2;

ssDistShear[x_, w_, L_] :=
  w (L / 2 - x);

(* --- Fixed-Fixed with Point Load at center --- *)
ffPointDeflection[x_, P_, L_, EI_] := Module[{a = L/2},
  Piecewise[{
    {-(P x^2 (3 a L - 3 a x - L x)) / (12 EI L^3) * L^2, 0 <= x <= L/2},
    {-(P (L - x)^2 (3 a L - 3 a (L - x) - L (L - x))) / (12 EI L^3) * L^2, L/2 < x <= L}
  }, 0]
];

ffPointMoment[x_, P_, L_] :=
  Piecewise[{
    {P L / 8 (4 x / L - 1), 0 <= x <= L/2},
    {P L / 8 (3 - 4 x / L), L/2 < x <= L}
  }, 0];

ffPointShear[x_, P_, L_] :=
  Piecewise[{
    {P / 2, 0 <= x < L/2},
    {-P / 2, L/2 <= x <= L}
  }, 0];

(* ══════════════════════════════════════════════════════════════════
   Stress Heatmap Color Function
   ══════════════════════════════════════════════════════════════════ *)
heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

(* ══════════════════════════════════════════════════════════════════
   3D Beam Visualization
   ══════════════════════════════════════════════════════════════════ *)
beam3D[deflFn_, L_, width_, height_, EI_, yieldStress_, deformScale_] := Module[
  {nx = 60, ny = 4, nz = 4, pts, colors, maxStress},

  (* Compute max bending stress for normalization *)
  maxStress = Max[Table[
    Module[{M = Abs[deflFn["moment", x]]},
      M * (height / 2) / calcI[width, height]
    ], {x, 0, L, L / 100}]];

  Graphics3D[{
    EdgeForm[None],
    Table[
      Module[{x = i * L / nx, xNext = (i + 1) * L / nx,
              def1, def2, stress, col},
        def1 = deflFn["deflection", x] * deformScale;
        def2 = deflFn["deflection", xNext] * deformScale;
        stress = Abs[deflFn["moment", x]] * (height / 2) / calcI[width, height];
        col = heatmapColor[If[maxStress > 0, stress / yieldStress, 0]];
        {col, Cuboid[
          {x, def1 - height/2, -width/2},
          {xNext, def2 + height/2, width/2}
        ]}
      ],
      {i, 0, nx - 1}
    ]
  },
    Boxed -> False, Lighting -> "Neutral",
    ViewPoint -> {2, 1.5, 1.5},
    ImageSize -> 500
  ]
];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimBeam[] := Manipulate[
  Module[{mat, EE, yieldS, Ival, EI, deflFn, maxDefl, maxM, maxV, maxBendStress, sf},

    mat = materials[material];
    EE = mat["E"];
    yieldS = mat["yieldStress"];
    Ival = calcI[width, height];
    EI = EE * Ival;

    (* Build deflection/moment/shear function based on support and load type *)
    deflFn = Switch[{support, loadType},
      {"Simply Supported", "Point Load"},
        <|
          "deflection" -> Function[x, ssPointDeflection[x, load, loadPos, beamLength, EI]],
          "moment" -> Function[x, ssPointMoment[x, load, loadPos, beamLength]],
          "shear" -> Function[x, ssPointShear[x, load, loadPos, beamLength]]
        |>,
      {"Cantilever", "Point Load"},
        <|
          "deflection" -> Function[x, cantPointDeflection[x, load, beamLength, EI]],
          "moment" -> Function[x, cantPointMoment[x, load, beamLength]],
          "shear" -> Function[x, cantPointShear[x, load, beamLength]]
        |>,
      {"Simply Supported", "Distributed"},
        <|
          "deflection" -> Function[x, ssDistDeflection[x, load/beamLength, beamLength, EI]],
          "moment" -> Function[x, ssDistMoment[x, load/beamLength, beamLength]],
          "shear" -> Function[x, ssDistShear[x, load/beamLength, beamLength]]
        |>,
      {"Fixed-Fixed", "Point Load"},
        <|
          "deflection" -> Function[x, ffPointDeflection[x, load, beamLength, EI]],
          "moment" -> Function[x, ffPointMoment[x, load, beamLength]],
          "shear" -> Function[x, ffPointShear[x, load, beamLength]]
        |>,
      _,
        <|
          "deflection" -> Function[x, ssPointDeflection[x, load, loadPos, beamLength, EI]],
          "moment" -> Function[x, ssPointMoment[x, load, loadPos, beamLength]],
          "shear" -> Function[x, ssPointShear[x, load, loadPos, beamLength]]
        |>
    ];

    (* Calculate key values *)
    maxDefl = Max[Table[Abs[deflFn["deflection", x]], {x, 0, beamLength, beamLength/200}]];
    maxM = Max[Table[Abs[deflFn["moment", x]], {x, 0, beamLength, beamLength/200}]];
    maxV = Max[Table[Abs[deflFn["shear", x]], {x, 0, beamLength, beamLength/200}]];
    maxBendStress = maxM * (height / 2) / Ival;
    sf = If[maxBendStress > 0, yieldS / maxBendStress, \[Infinity]];

    Column[{
      (* Readouts *)
      Panel[Grid[{
        {"Max Deflection", NumberForm[maxDefl * 1000, 4] <> " mm"},
        {"Max Moment", NumberForm[maxM / 1000, 4] <> " kN\[CenterDot]m"},
        {"Max Shear", NumberForm[maxV / 1000, 4] <> " kN"},
        {"Max Bending Stress", NumberForm[maxBendStress / 1*^6, 4] <> " MPa"},
        {"Safety Factor", If[sf == \[Infinity], "\[Infinity]",
          Style[NumberForm[sf, 3], If[sf >= 2, Darker[Green], If[sf >= 1, Orange, Red]]]]}
      }, Alignment -> Left, Spacings -> {2, 0.5}],
        "Beam Analysis Results", Background -> LightBlue],

      (* 3D Beam *)
      beam3D[deflFn, beamLength, width, height, EI, yieldS, deformScale],

      (* Diagrams *)
      GraphicsRow[{
        Plot[deflFn["moment", x], {x, 0, beamLength},
          PlotLabel -> "Bending Moment (N\[CenterDot]m)",
          Filling -> Axis, PlotStyle -> Blue, ImageSize -> 250],
        Plot[deflFn["shear", x], {x, 0, beamLength},
          PlotLabel -> "Shear Force (N)",
          Filling -> Axis, PlotStyle -> Red, ImageSize -> 250]
      }],
      Plot[deflFn["deflection", x] * 1000, {x, 0, beamLength},
        PlotLabel -> "Deflection (mm)",
        Filling -> Axis, PlotStyle -> Purple, ImageSize -> 500]
    }, Spacings -> 1]
  ],

  {{material, "Steel", "Material"}, Keys[materials]},
  {{support, "Simply Supported", "Support Type"},
    {"Simply Supported", "Cantilever", "Fixed-Fixed"}},
  {{loadType, "Point Load", "Load Type"}, {"Point Load", "Distributed"}},
  Delimiter,
  {{beamLength, 4.0, "Beam Length (m)"}, 0.5, 10, 0.1, Appearance -> "Labeled"},
  {{width, 0.05, "Width (m)"}, 0.01, 0.3, 0.005, Appearance -> "Labeled"},
  {{height, 0.1, "Height (m)"}, 0.01, 0.5, 0.005, Appearance -> "Labeled"},
  {{load, 50000, "Load (N)"}, 100, 500000, 100, Appearance -> "Labeled"},
  {{loadPos, 2.0, "Load Position (m)"}, 0.1, 9.9, 0.1, Appearance -> "Labeled"},
  {{deformScale, 100, "Deformation Scale"}, 1, 1000, 1, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {material, support, loadType, beamLength, width, height, load, loadPos, deformScale}
]

(* Run: MechSimBeam[] *)
