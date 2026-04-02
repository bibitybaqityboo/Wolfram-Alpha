(* ::Package:: *)

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   MechSimCombined.wl \[LongDash] Combined Loading Module (Wolfram Language)
   Simulates Axial, Bending, and Torsion loads simultaneously
   with optional point load at arbitrary position
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)

(* \[HorizontalLine]\[HorizontalLine] Material Database \[HorizontalLine]\[HorizontalLine] *)
materials = <|
  "Steel"     -> <|"E" -> 200*^9, "G" -> 79*^9, "yieldStress" -> 250*^6, "alpha" -> 12*^-6, "color" -> RGBColor[0.53, 0.6, 0.67]|>,
  "Aluminum"  -> <|"E" -> 69*^9,  "G" -> 26*^9, "yieldStress" -> 270*^6, "alpha" -> 23*^-6, "color" -> RGBColor[0.69, 0.72, 0.75]|>,
  "Titanium"  -> <|"E" -> 116*^9, "G" -> 44*^9, "yieldStress" -> 880*^6, "alpha" -> 8.6*^-6, "color" -> RGBColor[0.63, 0.66, 0.69]|>
|>;

(* \[HorizontalLine]\[HorizontalLine] Heatmap Color Function \[HorizontalLine]\[HorizontalLine] *)
heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Calculations (solid bar only)
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
calcCombined[P_, V_, T_, L_, r_, E_, G_, ptFx_:0, ptFy_:0, ptFz_:0, ptXp_:0,
  thermRig_:False, thermDT1_:0, thermDT2_:0, thermL_:1.0, thermD_:0.01, thermE_:200*^9, thermAlpha_:12*^-6, thermA_:0.0] := Module[
  {A, Ival, J, MmaxY, MmaxZ, Mmax, sigAxial, sigBend, sigXmax,
   tauTorsion, tauXYmax, sigAvg, Rval, p1, p2, vm, delL, delY, phi,
   Ks, Kr, Rarm, Ttotal, Frod1, Frod2},

  A = \[Pi] r^2;
  Ival = \[Pi]/4 r^4;
  J = \[Pi]/2 r^4;

  MmaxY = Abs[V * L + ptFy * ptXp];
  MmaxZ = Abs[ptFz * ptXp];
  Mmax = Sqrt[MmaxY^2 + MmaxZ^2];

  sigAxial = Max[Abs[P], Abs[P + ptFx]] / A;
  sigBend = (Mmax * r) / Ival;
  sigXmax = sigAxial + sigBend;

  (* Thermal Rig Indeterminate Torque Calculation *)
  If[thermRig,
    Ks = (G * J) / L;
    Kr = ((\[Pi] / 4 * thermD^2) * thermE) / thermL;
    Rarm = r + thermA;
    phi = (T + Kr * Rarm * thermAlpha * (thermDT1 - thermDT2) * thermL) / (Ks + 2 * Kr * Rarm^2);
    Ttotal = Ks * phi;
    Frod1 = Kr * (phi * Rarm - thermAlpha * thermDT1 * thermL);
    Frod2 = Kr * (-phi * Rarm - thermAlpha * thermDT2 * thermL);
  ,
    phi = (T * L) / (G * J);
    Ttotal = T;
    Frod1 = 0; Frod2 = 0;
  ];

  tauTorsion = (Ttotal * r) / J;
  tauXYmax = Abs[tauTorsion];

  sigAvg = sigXmax / 2;
  Rval = Sqrt[(sigAvg)^2 + tauXYmax^2];

  p1 = sigAvg + Rval;
  p2 = sigAvg - Rval;
  vm = Sqrt[p1^2 - p1 p2 + p2^2];

  delL = (P * L) / (A * E);
  delY = (V * L^3) / (3 * E * Ival);

  <|"sigmaX" -> sigXmax, "tauXY" -> tauXYmax, "p1" -> p1, "p2" -> p2, "vm" -> vm,
    "deltaL" -> delL, "deltaY" -> delY, "phi" -> phi, "A" -> A, "I" -> Ival, "J" -> J,
    "Frod1" -> Frod1, "Frod2" -> Frod2, "Ttotal" -> Ttotal|>
];

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   3D Visualization
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
visualizeShaft[P_, V_, Tapplied_, Ttotal_, L_, rOuter_, E_, G_, yield_, scale_,
  heatmapType_, zoom_, ptFx_:0, ptFy_:0, ptFz_:0, ptXp_:0,
  thermRig_:False, thermDT1_:0, thermDT2_:0, thermL_:1.0, thermD_:0.01, thermA_:0.0, Frod1_:0, Frod2_:0, cameraView_:"Perspective"] := Module[
  {A, Ival, J, deformX, deformY, deformZ, twist, colorFn,
   endX, endY, endZ, arrP, arrV, arrT, arrPt, support, plot3D,
   legendMax, legendLabel, nHelix, nRings, nPts, rDraw, helixLines, ringLines,
   ptXpC, endCap, endCapGrid, twistEnd, nSlices, nCircles,
   thermRigPlot, crossbar, rod1, rod2, pin1, pin2, lbl1, lbl2, Rarm, viewPt},

  A = \[Pi] rOuter^2;
  Ival = \[Pi]/4 rOuter^4;
  J = \[Pi]/2 rOuter^4;
  ptXpC = Clip[ptXp, {0, L}];

  (* \[HorizontalLine]\[HorizontalLine] Deformation functions (superposition) \[HorizontalLine]\[HorizontalLine] *)
  deformX[x_] := If[ptFx != 0 && ptXpC > 0,
    If[x <= ptXpC,
      (P + ptFx) * x / (A * E),
      (P + ptFx) * ptXpC / (A * E) + P * (x - ptXpC) / (A * E)],
    P * x / (A * E)] * scale;

  deformY[x_] := Module[{dEnd, dPt},
    dEnd = If[V != 0, (V * x^2) / (6 * E * Ival) * (3 * L - x), 0];
    dPt = If[ptFy != 0 && ptXpC > 0,
      If[x <= ptXpC,
        (ptFy * x^2) / (6 * E * Ival) * (3 * ptXpC - x),
        (ptFy * ptXpC^2) / (6 * E * Ival) * (3 * x - ptXpC)], 0];
    (dEnd + dPt) * scale];

  deformZ[x_] := If[ptFz != 0 && ptXpC > 0,
    If[x <= ptXpC,
      (ptFz * x^2) / (6 * E * Ival) * (3 * ptXpC - x),
      (ptFz * ptXpC^2) / (6 * E * Ival) * (3 * x - ptXpC)
    ] * scale, 0];

  twist[x_] := (Ttotal * x) / (G * J) * scale;

  (* \[HorizontalLine]\[HorizontalLine] Stress color function \[HorizontalLine]\[HorizontalLine] *)
  colorFn = Function[{x, y, z, u, v},
    Module[{rNode, th, actualY, MvalY, MvalZ, Mval, sx, txy, vmNode, stressRatio, xPos},
      rNode = rOuter; xPos = u * L;
      th = v - twist[xPos];
      actualY = rNode * Cos[th];
      MvalY = V * (L - xPos) + If[xPos <= ptXpC, ptFy * (ptXpC - xPos), 0];
      MvalZ = If[xPos <= ptXpC, ptFz * (ptXpC - xPos), 0];
      Mval = Sqrt[MvalY^2 + MvalZ^2];
      sx = (If[xPos <= ptXpC, P + ptFx, P]) / A - (Mval * actualY) / Ival;
      txy = Ttotal * rNode / J;
      vmNode = Sqrt[sx^2 + 3 txy^2];
      stressRatio = Which[
        heatmapType === "Normal Stress", Abs[sx] / yield,
        heatmapType === "Shear Stress",  Abs[txy] / (yield / Sqrt[3]),
        True,                            vmNode / yield];
      heatmapColor[stressRatio]
  ]];

  endX = L + deformX[L];
  endY = deformY[L];
  endZ = deformZ[L];
  twistEnd = twist[L];

  (* \[HorizontalLine]\[HorizontalLine] Support wall \[HorizontalLine]\[HorizontalLine] *)
  support = Graphics3D[{
    GrayLevel[0.6], Opacity[0.8],
    Cuboid[{-L*0.05, -rOuter*1.5, -rOuter*1.5}, {0, rOuter*1.5, rOuter*1.5}]
  }];

  (* \[HorizontalLine]\[HorizontalLine] End load arrows \[HorizontalLine]\[HorizontalLine] *)
  arrP = If[P != 0,
    Graphics3D[{Red, Arrowheads[0.05],
      Arrow[If[P > 0,
        {{endX, endY, endZ}, {endX + L*0.3, endY, endZ}},
        {{endX + L*0.3, endY, endZ}, {endX, endY, endZ}}]]
    }], Graphics3D[{}]];

  arrV = If[V != 0,
    Graphics3D[{Darker[Green], Arrowheads[0.05],
      Arrow[If[V > 0,
        {{endX, endY - L*0.3, endZ}, {endX, endY - rOuter*1.1, endZ}},
        {{endX, endY + L*0.3, endZ}, {endX, endY + rOuter*1.1, endZ}}]]
    }], Graphics3D[{}]];

  arrT = If[Tapplied != 0,
    Graphics3D[{Blue, Arrowheads[0.05],
      Table[Arrow[
        Table[{endX, endY + rOuter*1.3*Cos[th + Sign[Tapplied]*dTh],
               endZ + rOuter*1.3*Sin[th + Sign[Tapplied]*dTh]},
          {dTh, 0, Pi/3, Pi/12}]
      ], {th, 0, 3 Pi/2, Pi/2}]
    }], Graphics3D[{}]];

  (* \[HorizontalLine]\[HorizontalLine] Point load arrow (orange/magenta) \[HorizontalLine]\[HorizontalLine] *)
  arrPt = If[ptFx != 0 || ptFy != 0 || ptFz != 0,
    Module[{xPt, yPt, zPt, arrows = {}, aLen = L * 0.2},
      xPt = ptXpC + deformX[ptXpC];
      yPt = deformY[ptXpC];
      zPt = deformZ[ptXpC];
      If[ptFy != 0, AppendTo[arrows,
        {Orange, Arrowheads[0.05],
         Arrow[{{xPt, yPt + Sign[ptFy]*aLen, zPt}, {xPt, yPt, zPt}}]}]];
      If[ptFz != 0, AppendTo[arrows,
        {Magenta, Arrowheads[0.05],
         Arrow[{{xPt, yPt, zPt + Sign[ptFz]*aLen}, {xPt, yPt, zPt}}]}]];
      If[ptFx != 0, AppendTo[arrows,
        {Orange, Arrowheads[0.05],
         Arrow[{{xPt + Sign[ptFx]*aLen, yPt, zPt}, {xPt, yPt, zPt}}]}]];
      Graphics3D[arrows]
    ], Graphics3D[{}]];

  (* \[HorizontalLine]\[HorizontalLine] End cap: filled disk at free end \[HorizontalLine]\[HorizontalLine] *)
  endCap = ParametricPlot3D[
    {endX,
     rr * Cos[th + twistEnd] + endY,
     rr * Sin[th + twistEnd] + endZ},
    {rr, 0, rOuter}, {th, 0, 2 \[Pi]},
    Mesh -> None, PlotPoints -> {12, 30},
    PlotStyle -> Directive[GrayLevel[0.85], Opacity[0.9]],
    Boxed -> False, Axes -> False, Lighting -> "Neutral"
  ];

  (* \[HorizontalLine]\[HorizontalLine] Pizza-slice grid on end cap: radial lines + concentric circles \[HorizontalLine]\[HorizontalLine] *)
  nSlices = 12;
  nCircles = 4;

  endCapGrid = Graphics3D[{
    Directive[Black, Opacity[0.95]],
    (* Radial lines \[LongDash] like pizza slices *)
    Table[
      Tube[{
        {endX, endY, endZ},
        {endX,
         rOuter * Cos[k * 2 \[Pi] / nSlices + twistEnd] + endY,
         rOuter * Sin[k * 2 \[Pi] / nSlices + twistEnd] + endZ}
      }, rOuter * 0.007], {k, 0, nSlices - 1}],
    (* Concentric circles *)
    Table[
      Tube[Table[
        {endX,
         (j / nCircles) * rOuter * Cos[th + twistEnd] + endY,
         (j / nCircles) * rOuter * Sin[th + twistEnd] + endZ},
        {th, 0, 2 \[Pi] + 2 \[Pi] / 48, 2 \[Pi] / 48}], rOuter * 0.005
      ], {j, 1, nCircles}]
  }];

  (* \[HorizontalLine]\[HorizontalLine] Thermal Rig Visualization \[HorizontalLine]\[HorizontalLine] *)
  thermRigPlot = If[thermRig,
    Rarm = rOuter + thermA;
    Module[{rodR = thermD / 2, cY1, cZ1, cY2, cZ2},
      cY1 = endY + Rarm * Cos[twistEnd + 0];
      cZ1 = endZ + Rarm * Sin[twistEnd + 0];
      cY2 = endY + Rarm * Cos[twistEnd + Pi];
      cZ2 = endZ + Rarm * Sin[twistEnd + Pi];

      crossbar = Graphics3D[{
         GrayLevel[0.3],
         GeometricTransformation[
           Cuboid[{endX - rOuter*0.1, -Rarm, -rOuter*0.2}, {endX + rOuter*0.1, Rarm, rOuter*0.2}],
           RotationTransform[twistEnd, {1, 0, 0}, {endX, 0, 0}]
         ]
      }];

      rod1 = Graphics3D[{
         If[Frod1 > 0, Lighter[Blue, 0.5], Lighter[Red, 0.5]],
         Tube[{{endX, cY1, cZ1}, {endX, cY1, cZ1 - thermL}}, rodR]
      }];

      rod2 = Graphics3D[{
         If[Frod2 > 0, Lighter[Blue, 0.5], Lighter[Red, 0.5]],
         Tube[{{endX, cY2, cZ2}, {endX, cY2, cZ2 - thermL}}, rodR]
      }];

      pin1 = Graphics3D[{
         GrayLevel[0.5],
         Polygon[{{endX, cY1 - rOuter*0.2, cZ1 - thermL}, {endX, cY1 + rOuter*0.2, cZ1 - thermL}, {endX, cY1, cZ1 - thermL - rOuter*0.2}}]
      }];

      pin2 = Graphics3D[{
         GrayLevel[0.5],
         Polygon[{{endX, cY2 - rOuter*0.2, cZ2 - thermL}, {endX, cY2 + rOuter*0.2, cZ2 - thermL}, {endX, cY2, cZ2 - thermL - rOuter*0.2}}]
      }];

      lbl1 = Graphics3D[Text[Style[(If[thermDT1>=0,"+",""])<>ToString[thermDT1]<>"\[Degree]C", 14, Bold, If[thermDT1>=0,Red,Blue]], {endX, cY1 + rOuter*0.5, cZ1 - thermL/2}, {-1, 0}]];
      lbl2 = Graphics3D[Text[Style[(If[thermDT2>=0,"+",""])<>ToString[thermDT2]<>"\[Degree]C", 14, Bold, If[thermDT2>=0,Red,Blue]], {endX, cY2 - rOuter*0.5, cZ2 - thermL/2}, {1, 0}]];

      (* Upward point load arrows at the bottom of the rods *)
      Module[{arrLen = L * 0.15},
        Show[crossbar, rod1, rod2, pin1, pin2, lbl1, lbl2,
          If[Frod1 != 0, Graphics3D[{Darker[If[Frod1>0, Blue, Red]], Arrowheads[0.05], Arrow[{{endX, cY1, cZ1 - thermL + Sign[Frod1]*arrLen}, {endX, cY1, cZ1 - thermL}}]}] , Graphics3D[{}]],
          If[Frod2 != 0, Graphics3D[{Darker[If[Frod2>0, Blue, Red]], Arrowheads[0.05], Arrow[{{endX, cY2, cZ2 - thermL + Sign[Frod2]*arrLen}, {endX, cY2, cZ2 - thermL}}]}] , Graphics3D[{}]]
        ]
      ]
    ]
  , Graphics3D[{}]];

  viewPt = Which[
    cameraView === "Front View", {Infinity, 0, 0},
    cameraView === "Side View", {0, -Infinity, 0},
    True, {2, -2, 1.5}
  ];

  (* \[HorizontalLine]\[HorizontalLine] Assemble 3D plot \[HorizontalLine]\[HorizontalLine] *)
  plot3D = Show[
    support,
    ParametricPlot3D[
      {u * L + deformX[u * L],
       rOuter * Cos[v + twist[u * L]] + deformY[u * L],
       rOuter * Sin[v + twist[u * L]] + deformZ[u * L]},
      {u, 0, 1}, {v, 0, 2 \[Pi]},
      Mesh -> {20, 12}, MeshFunctions -> {#4 &, #5 &},
      MeshStyle -> Directive[Black, Opacity[0.6], Thickness[0.002]],
      PlotPoints -> {40, 40},
      ColorFunction -> colorFn,
      ColorFunctionScaling -> False, Boxed -> False, Axes -> False, Lighting -> "Neutral"
    ],
    endCap, endCapGrid, thermRigPlot,
    arrP, arrV, arrT, arrPt,
    ViewPoint -> viewPt, ViewProjection -> If[cameraView === "Front View" || cameraView === "Side View", "Orthographic", "Perspective"],
    ViewAngle -> (35 Degree) / zoom,
    PlotRange -> All, ImageSize -> 500, SphericalRegion -> True
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

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Main Interactive Panel
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
MechSimCombined[] := Manipulate[
  Module[{mat, eVal, gVal, yield, alpha, results, sf, plotBMD, ptXpC,
          thermMatProps, thermEVal, thermAlphaVal},
    mat = materials[material];
    eVal = mat["E"];
    gVal = mat["G"];
    yield = mat["yieldStress"];
    alpha = mat["alpha"];
    ptXpC = Clip[ptLoadPos, {0, length}];

    thermMatProps = materials[thermMat];
    thermEVal = thermMatProps["E"];
    thermAlphaVal = thermMatProps["alpha"];

    results = calcCombined[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3,
      length, outerR/1000, eVal, gVal,
      ptLoadFx * 10^3, ptLoadFy * 10^3, ptLoadFz * 10^3, ptXpC,
      thermEnable, thermDT1, thermDT2, thermL, thermD/1000, thermEVal, thermAlphaVal, thermA/1000];
    sf = If[results["vm"] > 0, yield / results["vm"], \[Infinity]];

    ControlActive[
      Column[{
        Style["\[ThinSpace] Computations Paused During Interaction...", 14, Bold, Gray],
        visualizeShaft[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3, results["Ttotal"], length,
          outerR/1000, eVal, gVal, yield, deformScale, heatmapType, magnification,
          ptLoadFx * 10^3, ptLoadFy * 10^3, ptLoadFz * 10^3,
          ptXpC, thermEnable, thermDT1, thermDT2, thermL, thermD/1000, thermA/1000, results["Frod1"], results["Frod2"], cameraView]
      }, Spacings -> 1, Alignment -> Center],

      Module[{},
        plotBMD = Plot[
          bentLoad * 10^3 * (length - x) +
            If[x <= ptXpC, ptLoadFy * 10^3 * (ptXpC - x), 0],
          {x, 0, length},
          PlotStyle -> Darker[Blue],
          Filling -> Axis,
        FillingStyle -> Directive[Opacity[0.4], Darker[Blue]],
        PlotLabel -> Style["Bending Moment Diagram M(x)", 12, Bold],
        AxesLabel -> {"x (m)", "Moment (N\[CenterDot]m)"},
        ImageSize -> 400, Exclusions -> None];

      Column[{
        Panel[Grid[{
          {Style["Max Normal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["sigmaX"] / 1*^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Torsional Shear (\!\(\*SubscriptBox[\(\[Tau]\), \(torsion\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["tauXY"] / 1*^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(1\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["p1"] / 1*^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(2\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["p2"] / 1*^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Von Mises Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(vm\)]\))", 12, Darker[Blue]],
           Style[ToString[NumberForm[results["vm"] / 1*^6, {6, 2}]] <> " MPa", 12, Bold,
             If[results["vm"] > yield, Red, Blue]]},
          {Style["Angle of Twist (\[Phi])", 12, Darker[Blue]],
           Style[ToString[NumberForm[results["phi"], {6, 4}]] <> " rad  (" <>
             ToString[NumberForm[N[results["phi"] * 180 / \[Pi]], {6, 2}]] <> "\[Degree])", 12, Bold, Blue]},
          {Style["Safety Factor", 11, Darker[Blue]],
           If[sf == \[Infinity], Style["\[Infinity]", 11, Bold],
             Style[NumberForm[sf, {5, 2}], 11, Bold,
               If[sf >= 2, Darker[Green], If[sf >= 1, Orange, Red]]]]}
        }, Alignment -> {{Left, Right}, Center}, Spacings -> {2, 0.8}, Dividers -> Center],
        Style["\[ThinSpace] Combined Loading Results", 14, Bold], Background -> White],

        If[results["vm"] > yield,
          Framed[Style["\[WarningSign] YIELD STRESS EXCEEDED ", 12, Bold, Darker[Red]],
            Background -> Lighter[Red, 0.9], FrameStyle -> Thick, FrameColor -> Darker[Red]], ""],

        visualizeShaft[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3, results["Ttotal"], length,
          outerR/1000, eVal, gVal, yield, deformScale, heatmapType,
          magnification, ptLoadFx * 10^3, ptLoadFy * 10^3, ptLoadFz * 10^3, ptXpC,
          thermEnable, thermDT1, thermDT2, thermL, thermD/1000, thermA/1000, results["Frod1"], results["Frod2"], cameraView],
        plotBMD
      }, Spacings -> 1, Alignment -> Center]
      ]
    ]
  ],

  Style["Visualization Settings", 12, Bold],
  {{cameraView, "Perspective", "Camera View"}, {"Perspective", "Front View", "Side View"}, ControlType -> RadioButtonBar},
  {{heatmapType, "Von Mises Stress", "Heatmap Display"},
    {"Von Mises Stress", "Normal Stress", "Shear Stress"}, ControlType -> RadioButtonBar},
  {{deformScale, 40, "Deformation Scale"}, 1, 100, 1, Appearance -> "Labeled"},
  {{magnification, 1, "Magnification \[Times]"}, 1, 20, 0.5, Appearance -> "Labeled"},
  Delimiter,
  Style["Material & Geometry", 12, Bold],
  {{material, "Steel", "Material"}, {"Steel", "Aluminum", "Titanium"}, ControlType -> SetterBar},
  {{length, 2.0, "Length L (m)"}, 0.5, 5.0, 0.1, Appearance -> "Labeled"},
  {{outerR, 50, "Outer Radius (mm)"}, 10, 150, 1, Appearance -> "Labeled"},
  Delimiter,
  Style["Applied Loads (at free end)", 12, Bold],
  {{axialLoad, 0, "Axial Load P (kN)"}, -500, 500, 5, Appearance -> "Labeled"},
  {{bentLoad, 0, "Transverse Load V (kN)"}, -100, 100, 1, Appearance -> "Labeled"},
  {{torsionLoad, 0, "Torque T (kN\[CenterDot]m)"}, -50, 50, 0.5, Appearance -> "Labeled"},
  Delimiter,
  Style["Point Load", 12, Bold],
  {{ptLoadPos, 1.0, "Position along bar (m)"}, 0.0, 5.0, 0.05, Appearance -> "Labeled"},
  {{ptLoadFx, 0, "Point Fx (kN)"}, -200, 200, 5, Appearance -> "Labeled"},
  {{ptLoadFy, 0, "Point Fy (kN)"}, -100, 100, 1, Appearance -> "Labeled"},
  {{ptLoadFz, 0, "Point Fz (kN)"}, -100, 100, 1, Appearance -> "Labeled"},
  Delimiter,
  Style["Thermal Torsion Rig", 12, Bold],
  {{thermEnable, False, "Enable Thermal Rig"}, {True, False}},
  {{thermDT1, 0, "Right Rod \[CapitalDelta]\!\(\*SubscriptBox[\(T\), \(1\)]\) (\[Degree]C)"}, -200, 200, 1, Appearance -> "Labeled"},
  {{thermDT2, 0, "Left Rod \[CapitalDelta]\!\(\*SubscriptBox[\(T\), \(2\)]\) (\[Degree]C)"}, -200, 200, 1, Appearance -> "Labeled"},
  {{thermMat, "Aluminum", "Rod Material"}, {"Steel", "Aluminum", "Titanium"}, ControlType -> SetterBar},
  {{thermL, 1.0, "Rod Length l (m)"}, 0.1, 3.0, 0.1, Appearance -> "Labeled"},
  {{thermD, 10, "Rod Diameter (mm)"}, 2, 50, 1, Appearance -> "Labeled"},
  {{thermA, 0, "Offset a from shaft surface (mm)"}, 0, 200, 5, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {heatmapType, cameraView, material, length, outerR,
    axialLoad, bentLoad, torsionLoad, deformScale, magnification,
    ptLoadPos, ptLoadFx, ptLoadFy, ptLoadFz,
    thermEnable, thermDT1, thermDT2, thermL, thermD, thermA, thermMat},
  SynchronousUpdating -> False
]

MechSimCombined[]
