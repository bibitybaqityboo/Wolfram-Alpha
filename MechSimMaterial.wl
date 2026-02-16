(* ══════════════════════════════════════════════════════════════════
   MechSimMaterial.wl — Material Testing Module (Wolfram Language)
   Virtual tensile test with stress-strain curves, Hollomon model,
   true stress/strain, toughness, and material comparison
   ══════════════════════════════════════════════════════════════════ *)

(* ── Tensile Test Material Properties ── *)
tensileMaterials = <|
  "Steel"     -> <|"E" -> 200*^3, "sigmaY" -> 250, "sigmaUlt" -> 400,
                   "strainUlt" -> 0.20, "strainFracture" -> 0.30, "n" -> 0.15,
                   "color" -> RGBColor[0.345, 0.651, 1.0]|>,
  "Aluminum"  -> <|"E" -> 69*^3, "sigmaY" -> 276, "sigmaUlt" -> 310,
                   "strainUlt" -> 0.12, "strainFracture" -> 0.17, "n" -> 0.20,
                   "color" -> RGBColor[0.749, 0.827, 0.906]|>,
  "Copper"    -> <|"E" -> 117*^3, "sigmaY" -> 70, "sigmaUlt" -> 220,
                   "strainUlt" -> 0.35, "strainFracture" -> 0.45, "n" -> 0.40,
                   "color" -> RGBColor[0.851, 0.549, 0.353]|>,
  "Titanium"  -> <|"E" -> 116*^3, "sigmaY" -> 880, "sigmaUlt" -> 950,
                   "strainUlt" -> 0.10, "strainFracture" -> 0.15, "n" -> 0.10,
                   "color" -> RGBColor[0.561, 0.471, 0.784]|>,
  "Cast Iron" -> <|"E" -> 170*^3, "sigmaY" -> 130, "sigmaUlt" -> 200,
                   "strainUlt" -> 0.005, "strainFracture" -> 0.006, "n" -> 0.01,
                   "color" -> RGBColor[0.49, 0.522, 0.565]|>,
  "Concrete"  -> <|"E" -> 30*^3, "sigmaY" -> 30, "sigmaUlt" -> 40,
                   "strainUlt" -> 0.002, "strainFracture" -> 0.003, "n" -> 0.05,
                   "color" -> RGBColor[0.5, 0.5, 0.5]|>
|>;

(* ══════════════════════════════════════════════════════════════════
   Stress-Strain Model (Hollomon Hardening)
   ══════════════════════════════════════════════════════════════════ *)

calcEngStress[strain_, mat_] := Module[
  {EE, sigmaY, sigmaUlt, strainUlt, strainFracture, nExp, strainYield,
   plasticStrain, maxPlasticStrain, KK, neckStrain, neckRange, t},

  EE = mat["E"]; sigmaY = mat["sigmaY"]; sigmaUlt = mat["sigmaUlt"];
  strainUlt = mat["strainUlt"]; strainFracture = mat["strainFracture"];
  nExp = mat["n"];
  strainYield = sigmaY / EE;

  Which[
    strain <= 0, 0,
    strain >= strainFracture, 0,
    strain <= strainYield,
      (* Linear elastic *)
      EE * strain,
    strain <= strainUlt,
      (* Plastic hardening — Hollomon's equation *)
      plasticStrain = strain - strainYield;
      maxPlasticStrain = strainUlt - strainYield;
      If[maxPlasticStrain <= 0, sigmaY,
        KK = (sigmaUlt - sigmaY) / maxPlasticStrain^nExp;
        sigmaY + KK * plasticStrain^nExp
      ],
    True,
      (* Necking — parabolic drop *)
      neckStrain = strain - strainUlt;
      neckRange = strainFracture - strainUlt;
      If[neckRange <= 0, 0,
        t = neckStrain / neckRange;
        sigmaUlt * (1 - t^2)
      ]
  ]
];

(* True stress = σ_eng × (1 + ε_eng) — valid only up to UTS *)
calcTrueStress[strain_, mat_] := Module[{engStress, cappedStrain},
  engStress = calcEngStress[strain, mat];
  If[strain >= mat["strainFracture"], Return[0]];
  If[strain > mat["strainUlt"],
    (* After necking, cap at UTS true stress *)
    Module[{utsStress = calcEngStress[mat["strainUlt"], mat]},
      utsStress * (1 + mat["strainUlt"])
    ],
    engStress * (1 + strain)
  ]
];

calcTrueStrain[strain_] := If[strain <= 0, 0, Log[1 + strain]];

(* ── Toughness = area under σ-ε curve (trapezoidal) ── *)
calcToughness[mat_] := Module[{steps = 500, dStrain, area = 0},
  dStrain = mat["strainFracture"] / steps;
  Do[
    Module[{s1 = calcEngStress[i * dStrain, mat],
            s2 = calcEngStress[(i + 1) * dStrain, mat]},
      area += (s1 + s2) / 2 * dStrain
    ],
    {i, 0, steps - 1}
  ];
  area (* MJ/m³ since stress in MPa and strain unitless *)
];

(* ── Resilience = σ_y² / (2E) ── *)
calcResilience[mat_] := mat["sigmaY"]^2 / (2 mat["E"]);

(* ══════════════════════════════════════════════════════════════════
   Stress-Strain Curve Plot
   ══════════════════════════════════════════════════════════════════ *)

stressStrainPlot[mat1Name_, mat2Name_, showComparison_, useTrue_, currentStrain_] :=
  Module[{mat1, mat2, plots = {}, epilogs = {},
          maxStrain, maxStress, stressFn1, stressFn2, strainFn,
          currentStress1, yieldLine},

    mat1 = tensileMaterials[mat1Name];

    stressFn1 = If[useTrue,
      Function[s, calcTrueStress[s, mat1]],
      Function[s, calcEngStress[s, mat1]]
    ];
    strainFn = If[useTrue, calcTrueStrain, Identity];

    maxStrain = mat1["strainFracture"] * 1.1;
    maxStress = mat1["sigmaUlt"] * 1.4;

    AppendTo[plots,
      Plot[stressFn1[s], {s, 0, mat1["strainFracture"]},
        PlotStyle -> {Thick, mat1["color"]},
        PlotRange -> All]
    ];

    If[showComparison && mat2Name =!= mat1Name,
      mat2 = tensileMaterials[mat2Name];
      stressFn2 = If[useTrue,
        Function[s, calcTrueStress[s, mat2]],
        Function[s, calcEngStress[s, mat2]]
      ];
      AppendTo[plots,
        Plot[stressFn2[s], {s, 0, mat2["strainFracture"]},
          PlotStyle -> {Thick, Dashed, mat2["color"]},
          PlotRange -> All]
      ];
      maxStrain = Max[maxStrain, mat2["strainFracture"] * 1.1];
      maxStress = Max[maxStress, mat2["sigmaUlt"] * 1.4];
    ];

    (* Current strain marker *)
    currentStress1 = stressFn1[currentStrain];

    Show[plots,
      PlotLabel -> If[useTrue, "True Stress-Strain Curve", "Engineering Stress-Strain Curve"],
      AxesLabel -> {
        If[useTrue, "True Strain", "Engineering Strain"],
        If[useTrue, "True Stress (MPa)", "Engineering Stress (MPa)"]
      },
      PlotRange -> {{0, maxStrain}, {0, maxStress}},
      ImageSize -> 550,
      GridLines -> {None, {mat1["sigmaY"]}},
      GridLinesStyle -> Directive[Gray, Dashed],
      Epilog -> {
        (* Current point marker *)
        {Magenta, PointSize[Large],
         Point[{strainFn[currentStrain], currentStress1}]},
        (* Yield stress label *)
        Text[Style["\[Sigma]_y = " <> ToString[mat1["sigmaY"]] <> " MPa",
          9, Gray], Scaled[{0.85, 0.3}]],
        (* Legend *)
        Text[Style["\[FilledCircle] " <> mat1Name, 10, mat1["color"]],
          Scaled[{0.15, 0.93}]],
        If[showComparison && mat2Name =!= mat1Name,
          Text[Style["\[FilledCircle] " <> mat2Name, 10,
            tensileMaterials[mat2Name]["color"]], Scaled[{0.35, 0.93}]],
          Nothing]
      }
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   3D Specimen Deformation
   ══════════════════════════════════════════════════════════════════ *)

specimen3D[currentStrain_, mat_] :=
  Module[{isNecking, isFractured, neckProgress, height = 2.0, radius = 0.15},

    isFractured = currentStrain >= mat["strainFracture"];
    isNecking = currentStrain > mat["strainUlt"];

    Graphics3D[{
      EdgeForm[None],

      (* Specimen — series of discs *)
      Table[
        Module[{yNorm = i / 30, y, r, gap = 0},
          y = (yNorm - 0.5) * height * (1 + currentStrain);

          r = radius;
          (* Poisson contraction *)
          r *= (1 - 0.3 * Min[currentStrain, mat["sigmaY"] / mat["E"]]);

          (* Necking *)
          If[isNecking && !isFractured,
            neckProgress = (currentStrain - mat["strainUlt"]) / (mat["strainFracture"] - mat["strainUlt"]);
            Module[{distFromCenter = Abs[yNorm - 0.5] * 2},
              r *= (1 - neckProgress * 0.6 * Exp[-distFromCenter^2 * 4])
            ]
          ];

          (* Fracture gap *)
          If[isFractured,
            gap = (currentStrain - mat["strainFracture"]) * 2;
            If[yNorm > 0.5, y += gap, y -= gap];
            r *= 0.8
          ];

          (* Stress color *)
          Module[{stress = calcEngStress[currentStrain, mat],
                  t = Clip[Abs[calcEngStress[currentStrain, mat]] / mat["sigmaUlt"], {0, 1}],
                  col},
            col = Blend[{Blue, Green, Yellow, Red}, t];
            {col, Cylinder[{{0, y, 0}, {0, y + height / 30, 0}}, r]}
          ]
        ],
        {i, 0, 29}
      ],

      (* Grips *)
      {Darker[Gray], Opacity[0.8],
       Cuboid[{-0.3, -height * (1 + currentStrain) / 2 - 0.4, -0.3},
              {0.3, -height * (1 + currentStrain) / 2 - 0.15, 0.3}],
       Cuboid[{-0.3, height * (1 + currentStrain) / 2 + 0.15, -0.3},
              {0.3, height * (1 + currentStrain) / 2 + 0.4, 0.3}]}
    },
      Boxed -> False, Lighting -> "Neutral",
      ViewPoint -> {2, 1.2, 1.5},
      ImageSize -> 350, PlotRange -> All
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimMaterial[] := Manipulate[
  Module[{mat, stress, trueS, toughness, resilience},

    mat = tensileMaterials[material1];
    stress = calcEngStress[testStrain, mat];
    trueS = calcTrueStress[testStrain, mat];
    toughness = calcToughness[mat];
    resilience = calcResilience[mat];

    Column[{
      (* Results *)
      Panel[Grid[{
        {"Young's Modulus", ToString[mat["E"] / 1000] <> " GPa"},
        {"Yield Stress", ToString[mat["sigmaY"]] <> " MPa"},
        {"Ultimate Stress", ToString[mat["sigmaUlt"]] <> " MPa"},
        {"", ""},
        {"Current Strain", NumberForm[testStrain * 100, 4] <> "%"},
        {"Eng. Stress", NumberForm[stress, 4] <> " MPa"},
        {"True Stress", NumberForm[trueS, 4] <> " MPa"},
        {"", ""},
        {"Toughness", NumberForm[toughness, 4] <> " MJ/m\[Cubed]"},
        {"Resilience", NumberForm[resilience * 1000, 4] <> " kJ/m\[Cubed]"},
        {"", ""},
        If[testStrain >= mat["strainFracture"],
          {"Status", Style["FRACTURED", 14, Red, Bold]},
          If[testStrain > mat["strainUlt"],
            {"Status", Style["NECKING", 12, Orange, Bold]},
            If[testStrain > mat["sigmaY"] / mat["E"],
              {"Status", Style["Plastic Deformation", 11, Blue]},
              {"Status", Style["Elastic Region", 11, Darker[Green]]}
            ]
          ]
        ]
      }, Alignment -> Left, Spacings -> {2, 0.3}],
        "Material Testing Results", Background -> LightPurple],

      (* Side by side: Specimen + Curve *)
      Row[{
        specimen3D[testStrain, mat],
        Spacer[20],
        stressStrainPlot[material1, material2, compare, trueStressToggle, testStrain]
      }]
    }, Spacings -> 1]
  ],

  {{material1, "Steel", "Primary Material"}, Keys[tensileMaterials]},
  {{compare, False, "Compare Materials"}, {True, False}},
  {{material2, "Aluminum", "Comparison Material"}, Keys[tensileMaterials]},
  {{trueStressToggle, False, "True Stress/Strain"}, {True, False}},
  Delimiter,
  {{testStrain, 0.05, "Current Strain"}, 0, 0.50, 0.001, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {material1, material2, compare, trueStressToggle, testStrain}
]

(* Run: MechSimMaterial[] *)
