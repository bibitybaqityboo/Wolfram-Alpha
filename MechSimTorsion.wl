(* ══════════════════════════════════════════════════════════════════
   MechSimTorsion.wl — Torsion Module (Wolfram Language)
   Circular shaft analysis with power transmission & safety factor
   ══════════════════════════════════════════════════════════════════ *)

(* ── Material Database ── *)
torsionMaterials = <|
  "Steel"     -> <|"G" -> 79*^9,  "yieldStress" -> 250*^6|>,
  "Aluminum"  -> <|"G" -> 26*^9,  "yieldStress" -> 276*^6|>,
  "Titanium"  -> <|"G" -> 44*^9,  "yieldStress" -> 880*^6|>,
  "Copper"    -> <|"G" -> 45*^9,  "yieldStress" -> 70*^6|>,
  "Cast Iron" -> <|"G" -> 65*^9,  "yieldStress" -> 130*^6|>
|>;

(* ── Polar Moment of Inertia ── *)
calcJ[outerR_, innerR_, hollow_] := If[hollow,
  (Pi / 2) (outerR^4 - innerR^4),
  (Pi / 2) outerR^4
];

(* ── Torsion Calculations ── *)
calcTorsion[T_, L_, outerR_, innerR_, hollow_, G_, yieldStress_] :=
  Module[{J, tauMax, phi, yieldShear, sf},
    J = calcJ[outerR, innerR, hollow];
    tauMax = T * outerR / J;
    phi = T * L / (G * J);
    yieldShear = yieldStress * 0.577; (* von Mises: τ_y = σ_y / √3 *)
    sf = If[Abs[tauMax] > 0, yieldShear / Abs[tauMax], Infinity];
    <|"tauMax" -> tauMax, "phi" -> phi, "J" -> J, "sf" -> sf|>
  ];

(* ── Stress Heatmap ── *)
heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

(* ══════════════════════════════════════════════════════════════════
   3D Twisted Shaft Visualization
   ══════════════════════════════════════════════════════════════════ *)

twistedShaft3D[outerR_, innerR_, hollow_, L_, phi_, deformScale_, yieldShear_, tauMax_] :=
  Module[{nTheta = 32, nZ = 50, pts, polys = {}, colors = {}},

    Graphics3D[{
      EdgeForm[None],
      (* Outer surface *)
      Table[
        Module[{z = iz * L / nZ, zNext = (iz + 1) * L / nZ,
                twist1, twist2, theta1, theta2, r = outerR},
          twist1 = phi * (iz / nZ) * deformScale;
          twist2 = phi * ((iz + 1) / nZ) * deformScale;
          Table[
            Module[{t1 = it * 2 Pi / nTheta, t2 = (it + 1) * 2 Pi / nTheta,
                    stress, col},
              (* Stress at outer surface is tauMax *)
              stress = Abs[tauMax];
              col = heatmapColor[Clip[stress / yieldShear, {0, 1}]];
              {col, Polygon[{
                {r Cos[t1 + twist1], r Sin[t1 + twist1], z},
                {r Cos[t2 + twist1], r Sin[t2 + twist1], z},
                {r Cos[t2 + twist2], r Sin[t2 + twist2], zNext},
                {r Cos[t1 + twist2], r Sin[t1 + twist2], zNext}
              }]}
            ],
            {it, 0, nTheta - 1}
          ]
        ],
        {iz, 0, nZ - 1}
      ],

      (* Fixed wall *)
      {Darker[Gray], Cuboid[{-outerR * 1.5, -outerR * 1.5, -0.05},
                             {outerR * 1.5, outerR * 1.5, 0}]},

      (* Torque arrow at free end *)
      {If[tauMax > 0, Darker[Green], Red], Thick,
       Arrow[BSplineCurve[Table[
         {outerR * 1.3 * Cos[t], outerR * 1.3 * Sin[t], L + 0.05},
         {t, 0, 3 Pi/2, Pi/8}
       ]]]}
    },
      Boxed -> False, Lighting -> "Neutral",
      ViewPoint -> {2.5, 1.2, 1.0},
      ImageSize -> 450,
      PlotRange -> All
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   Shear Stress Distribution Plot
   ══════════════════════════════════════════════════════════════════ *)

shearDistPlot[outerR_, innerR_, hollow_, tauMax_] :=
  Module[{rMin = If[hollow, innerR, 0]},
    Plot[
      tauMax * r / outerR,
      {r, rMin, outerR},
      PlotLabel -> "Shear Stress Distribution",
      AxesLabel -> {"Radius (m)", "\[Tau] (Pa)"},
      Filling -> Axis,
      PlotStyle -> {Thick, Orange},
      ImageSize -> 400
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimTorsion[] := Manipulate[
  Module[{mat, G, yieldS, yieldShear, res, power, omega},

    mat = torsionMaterials[material];
    G = mat["G"];
    yieldS = mat["yieldStress"];
    yieldShear = yieldS * 0.577;
    res = calcTorsion[torque, shaftLength, outerR / 1000, innerR / 1000, hollow, G, yieldS];

    omega = If[rpm > 0, 2 Pi rpm / 60, 0];
    power = Abs[torque] * omega;

    Column[{
      (* Results *)
      Panel[Grid[{
        {"Max Shear Stress", NumberForm[Abs[res["tauMax"]] / 1*^6, 4] <> " MPa"},
        {"Angle of Twist", NumberForm[Abs[res["phi"]] * 180 / Pi, 4] <> "\[Degree]"},
        {"Polar Moment J", NumberForm[res["J"] * 1*^8, 5] <> " cm\[FourthPower]"},
        {"Power", If[rpm > 0,
          If[power >= 1*^6, NumberForm[power / 1*^6, 4] <> " MW",
           If[power >= 1*^3, NumberForm[power / 1*^3, 4] <> " kW",
            NumberForm[power, 4] <> " W"]],
          "N/A (set RPM)"]},
        {"Safety Factor", Style[
          If[res["sf"] == Infinity, "\[Infinity]", NumberForm[res["sf"], 3]],
          If[res["sf"] >= 2, Darker[Green], If[res["sf"] >= 1, Orange, Red]]]}
      }, Alignment -> Left, Spacings -> {2, 0.5}],
        "Torsion Analysis Results", Background -> LightYellow],

      (* 3D Shaft *)
      twistedShaft3D[outerR / 1000, innerR / 1000, hollow,
        shaftLength, res["phi"], deformScale, yieldShear, res["tauMax"]],

      (* Stress Distribution *)
      shearDistPlot[outerR / 1000, innerR / 1000, hollow, res["tauMax"]]
    }, Spacings -> 1]
  ],

  {{material, "Steel", "Material"}, Keys[torsionMaterials]},
  Delimiter,
  {{shaftLength, 2.0, "Length (m)"}, 0.5, 5.0, 0.1, Appearance -> "Labeled"},
  {{outerR, 50, "Outer Radius (mm)"}, 10, 200, 1, Appearance -> "Labeled"},
  {{hollow, False, "Hollow Shaft"}, {True, False}},
  {{innerR, 25, "Inner Radius (mm)"}, 5, 195, 1, Appearance -> "Labeled"},
  {{torque, 10000, "Torque (N\[CenterDot]m)"}, 100, 100000, 100, Appearance -> "Labeled"},
  {{rpm, 0, "RPM"}, 0, 10000, 10, Appearance -> "Labeled"},
  {{deformScale, 20, "Deformation Scale"}, 1, 100, 1, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {material, shaftLength, outerR, innerR, hollow, torque, rpm, deformScale}
]

(* Run: MechSimTorsion[] *)
