(* ══════════════════════════════════════════════════════════════════
   MechSimCombined.wl — Combined Loading Module (Wolfram Language)
   Simulates Axial, Bending, and Torsion loads simultaneously
   ══════════════════════════════════════════════════════════════════ *)

(* ── Material Database ── *)
materials = <|
  "Steel"     -> <|"E" -> 200*^9, "G" -> 79*^9, "yieldStress" -> 250*^6, "color" -> RGBColor[0.53, 0.6, 0.67]|>,
  "Aluminum"  -> <|"E" -> 69*^9,  "G" -> 26*^9, "yieldStress" -> 270*^6, "color" -> RGBColor[0.69, 0.72, 0.75]|>,
  "Titanium"  -> <|"E" -> 116*^9, "G" -> 44*^9, "yieldStress" -> 880*^6, "color" -> RGBColor[0.63, 0.66, 0.69]|>
|>;

(* ── Heatmap Color Function ── *)
heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

(* ══════════════════════════════════════════════════════════════════
   Calculations
   ══════════════════════════════════════════════════════════════════ *)
calcCombined[P_, V_, T_, L_, r_, ri_, E_, G_] := Module[
  {A, Ival, J, Mmax, sigAxial, sigBend, sigXmax, tauTorsion, tauXYmax, sigAvg, Rval, p1, p2, vm, delL, delY, phi},
  
  A = \[Pi] (r^2 - ri^2);
  Ival = \[Pi]/4 (r^4 - ri^4);
  J = \[Pi]/2 (r^4 - ri^4);
  
  Mmax = Abs[V] * L;
  
  sigAxial = P / A;
  sigBend = (Mmax * r) / Ival;
  sigXmax = Abs[sigAxial] + Abs[sigBend];
  
  tauTorsion = (T * r) / J;
  tauXYmax = Abs[tauTorsion];
  
  sigAvg = sigXmax / 2;
  Rval = Sqrt[(sigAvg)^2 + tauXYmax^2];
  
  p1 = sigAvg + Rval;
  p2 = sigAvg - Rval;
  vm = Sqrt[p1^2 - p1 p2 + p2^2];
  
  delL = (P * L) / (A * E);
  delY = (V * L^3) / (3 * E * Ival);
  phi = (T * L) / (G * J);
  
  <|"sigmaX" -> sigXmax, "tauXY" -> tauXYmax, "p1" -> p1, "p2" -> p2, "vm" -> vm,
    "deltaL" -> delL, "deltaY" -> delY, "phi" -> phi, "A" -> A, "I" -> Ival, "J" -> J|>
];

(* ══════════════════════════════════════════════════════════════════
   3D Visualization
   ══════════════════════════════════════════════════════════════════ *)
visualizeShaft[P_, V_, T_, L_, rOuter_, rInner_, E_, G_, yield_, scale_, heatmapType_] := Module[
  {A, Ival, J, deformX, deformY, twist, Mx, sigX, tauXY, nodeVM, colorFn, meshRange, endX, endY, arrP, arrV, arrT, support, plot3D, legendMax, legendLabel},

  A = \[Pi] (rOuter^2 - rInner^2);
  Ival = \[Pi]/4 (rOuter^4 - rInner^4);
  J = \[Pi]/2 (rOuter^4 - rInner^4);

  (* Deformation functions over length x *)
  deformX[x_] := (P * x) / (A * E) * scale;
  (* Bending cantilever equation *)
  deformY[x_] := If[V != 0, (V * x^2) / (6 * E * Ival) * (3 * L - x) * scale, 0];
  twist[x_] := (T * x) / (G * J) * scale;

  (* Stress at point (x, theta, rNode) *)
  (* Bending Moment M(x) = V*(L - x). Max stress is at y = rNode * Cos[theta] *)
  colorFn = Function[{x, y, z, u, v}, Module[{rNode, th, actualY, Mval, sx, txy, vmNode, stressRatio},
    rNode = rOuter; (* Map outer surface color *)
    th = v - twist[u * L];
    actualY = rNode * Cos[th];
    Mval = V * (L - u * L);
    sx = P / A - (Mval * actualY) / Ival;
    txy = T * rNode / J;
    vmNode = Sqrt[sx^2 + 3 txy^2];
    
    stressRatio = Which[
      heatmapType === "Normal Stress", Abs[sx] / yield,
      heatmapType === "Shear Stress",  Abs[txy] / (yield / Sqrt[3]),
      True,                            vmNode / yield
    ];
    heatmapColor[stressRatio]
  ]];

  endX = L + deformX[L];
  endY = deformY[L];
  
  support = Graphics3D[{
    GrayLevel[0.6], Opacity[0.8], 
    Cuboid[{-L*0.05, -rOuter*1.5, -rOuter*1.5}, {0, rOuter*1.5, rOuter*1.5}]
  }];
  
  arrP = If[P != 0, 
    Graphics3D[{Red, Arrowheads[0.05], 
      Arrow[If[P > 0, 
        {{endX, endY, 0}, {endX + L*0.3, endY, 0}}, 
        {{endX + L*0.3, endY, 0}, {endX, endY, 0}}]]
    }], 
    Graphics3D[{}]
  ];
  
  arrV = If[V != 0,
    Graphics3D[{Darker[Green], Arrowheads[0.05], 
      Arrow[If[V > 0, 
        {{endX, endY - L*0.3, 0}, {endX, endY - rOuter*1.1, 0}}, 
        {{endX, endY + L*0.3, 0}, {endX, endY + rOuter*1.1, 0}}]]
    }], 
    Graphics3D[{}]
  ];

  arrT = If[T != 0,
    Graphics3D[{Blue, Arrowheads[0.05], 
      Table[Arrow[
        Table[{endX, endY + rOuter*1.3*Cos[th + Sign[T]*dTh], rOuter*1.3*Sin[th + Sign[T]*dTh]}, {dTh, 0, Pi/3, Pi/12}]
      ], {th, 0, 3 Pi/2, Pi/2}]
    }], 
    Graphics3D[{}]
  ];

  plot3D = Show[
    support,
    ParametricPlot3D[
      {u * L + deformX[u * L],
       rOuter * Cos[v + twist[u * L]] + deformY[u * L],
       rOuter * Sin[v + twist[u * L]]},
      {u, 0, 1}, {v, 0, 2 \[Pi]},
      Mesh -> False, PlotPoints -> {30, 30},
      ColorFunction -> colorFn,
      ColorFunctionScaling -> False, Boxed -> False, Axes -> False, Lighting -> "Neutral"
    ],
    If[rInner > 0,
      ParametricPlot3D[
        {u * L + deformX[u * L],
         rInner * Cos[v + twist[u * L]] + deformY[u * L],
         rInner * Sin[v + twist[u * L]]},
        {u, 0, 1}, {v, 0, 2 \[Pi]},
        Mesh -> False, PlotPoints -> {20, 20},
        PlotStyle -> GrayLevel[0.8], Boxed -> False, Axes -> False
      ],
      Graphics3D[{}]
    ],
    arrP, arrV, arrT,
    ViewPoint -> {2, -2, 1.5}, PlotRange -> All, ImageSize -> 500
  ];
  
  legendMax = Which[
    heatmapType === "Normal Stress", yield,
    heatmapType === "Shear Stress",  yield / Sqrt[3],
    True,                            yield
  ];
  legendLabel = Which[
    heatmapType === "Normal Stress", "Max Normal Stress (MPa)",
    heatmapType === "Shear Stress",  "Max Shear Stress (MPa)",
    True,                            "Von Mises Stress (MPa)"
  ];

  Legended[plot3D, BarLegend[{heatmapColor[# / (legendMax/1*^6)] &, {0, legendMax/1*^6}}, 
    LegendLabel -> Style[legendLabel, 12, Bold, Black],
    LegendMarkerSize -> 300,
    LabelStyle -> {FontSize -> 11}
  ]]
];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimCombined[] := Manipulate[
  Module[{mat, E, G, yield, results, rFinalInner, sf, plotBMD},

    mat = materials[material];
    E = mat["E"];
    G = mat["G"];
    yield = mat["yieldStress"];
    rFinalInner = If[innerR >= outerR, outerR - 0.005, innerR];

    Pause[0.5];

    results = calcCombined[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3, length, outerR/1000, rFinalInner/1000, E, G];
    sf = If[results["vm"] > 0, yield / results["vm"], \[Infinity]];

    plotBMD = Plot[bentLoad * 10^3 * (length - x), {x, 0, length}, 
     PlotStyle -> If[bentLoad > 0, Red, Darker[Green]], 
     Filling -> Axis, 
     FillingStyle -> Directive[Opacity[0.4], If[bentLoad > 0, Red, Darker[Green]]], 
     PlotLabel -> Style["Bending Moment Diagram M(x)", 12, Bold], 
     AxesLabel -> {"x (m)", "Moment (N\[CenterDot]m)"}, 
     ImageSize -> 400];

    Column[{
      Panel[Grid[{
        {Style["Max Normal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\))", 11], Style[NumberForm[results["sigmaX"] / 1*^6, {6, 2}] <> " MPa", 11, Bold, Blue]},
        {Style["Max Shear Stress (\!\(\*SubscriptBox[\(\[Tau]\), \(xy\)]\))", 11], Style[NumberForm[results["tauXY"] / 1*^6, {6, 2}] <> " MPa", 11, Bold, Blue]},
        {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(1\)]\))", 11], Style[NumberForm[results["p1"] / 1*^6, {6, 2}] <> " MPa", 11, Bold, Blue]},
        {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(2\)]\))", 11], Style[NumberForm[results["p2"] / 1*^6, {6, 2}] <> " MPa", 11, Bold, Blue]},
        {Style["Von Mises Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(vm\)]\))", 12, Darker[Blue]], Style[NumberForm[results["vm"] / 1*^6, {6, 2}] <> " MPa", 12, Bold, If[results["vm"] > yield, Red, Blue]]},
        {Style["Safety Factor", 11], If[sf == \[Infinity], Style["\[Infinity]", 11, Bold], Style[NumberForm[sf, {5, 2}], 11, Bold, If[sf >= 2, Darker[Green], If[sf >= 1, Orange, Red]]]]}
      }, Alignment -> {{Left, Right}, Center}, Spacings -> {2, 0.8}, Dividers -> Center], 
      Style["\[ThinSpace] Combined Loading Results", 14, Bold], Background -> White],
      
      If[results["vm"] > yield, Framed[Style["\[WarningSign] YIELD STRESS EXCEEDED ", 12, Bold, Darker[Red]], Background -> Lighter[Red, 0.9], FrameStyle -> Thick, FrameColor -> Darker[Red]], ""],

      visualizeShaft[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3, length, outerR/1000, rFinalInner/1000, E, G, yield, deformScale, heatmapType],
      plotBMD
    }, Spacings -> 1, Alignment -> Center]
  ],

  Style["Visualization Settings", 12, Bold],
  {{heatmapType, "Von Mises Stress", "Heatmap Display"}, {"Von Mises Stress", "Normal Stress", "Shear Stress"}, ControlType -> RadioButtonBar},
  {{deformScale, 20, "Deformation Scale"}, 1, 100, 1, Appearance -> "Labeled"},
  Delimiter,
  Style["Material & Geometry", 12, Bold],
  {{material, "Steel", "Material"}, {"Steel", "Aluminum", "Titanium"}, ControlType -> SetterBar},
  {{length, 2.0, "Length L (m)"}, 0.5, 5.0, 0.1, Appearance -> "Labeled"},
  {{outerR, 50, "Outer Radius (mm)"}, 10, 150, 1, Appearance -> "Labeled"},
  {{innerR, 0, "Inner Radius (mm)"}, 0, 140, 1, Appearance -> "Labeled"},
  Delimiter,
  Style["Applied Loads (at free end)", 12, Bold],
  {{axialLoad, 0, "Axial Load P (kN)"}, -500, 500, 5, Appearance -> "Labeled"},
  {{bentLoad, 0, "Transverse Load V (kN)"}, -100, 100, 1, Appearance -> "Labeled"},
  {{torsionLoad, 0, "Torque T (kN\[CenterDot]m)"}, -50, 50, 0.5, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {heatmapType, material, length, outerR, innerR, axialLoad, bentLoad, torsionLoad, deformScale}
]

MechSimCombined[]
