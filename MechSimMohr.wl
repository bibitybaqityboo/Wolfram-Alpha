(* ══════════════════════════════════════════════════════════════════
   MechSimMohr.wl — Mohr's Circle Module (Wolfram Language)
   2D & 3D stress transformation with failure criteria
   ══════════════════════════════════════════════════════════════════ *)

(* ══════════════════════════════════════════════════════════════════
   Core Calculations
   ══════════════════════════════════════════════════════════════════ *)

mohrCalc[sx_, sy_, txy_] := Module[{center, R, s1, s2, tmax, thetaP},
  center = (sx + sy) / 2;
  R = Sqrt[((sx - sy) / 2)^2 + txy^2];
  s1 = center + R;
  s2 = center - R;
  tmax = R;
  thetaP = 0.5 * ArcTan[sx - sy, 2 txy] * 180 / Pi;
  <|"center" -> center, "R" -> R, "s1" -> s1, "s2" -> s2,
    "tmax" -> tmax, "thetaP" -> thetaP|>
];

(* Von Mises stress (2D plane stress: σ_z = 0) *)
vonMises2D[s1_, s2_] := Sqrt[s1^2 - s1 s2 + s2^2];

(* Tresca criterion *)
tresca[s1_, s2_] := Max[Abs[s1 - s2], Abs[s1], Abs[s2]];

(* Stress at arbitrary angle θ *)
stressAtAngle[sx_, sy_, txy_, theta_] := Module[{sn, tn},
  sn = (sx + sy)/2 + (sx - sy)/2 * Cos[2 theta] + txy * Sin[2 theta];
  tn = -(sx - sy)/2 * Sin[2 theta] + txy * Cos[2 theta];
  {sn, tn}
];

(* ══════════════════════════════════════════════════════════════════
   3D Stress Cube Visualization
   ══════════════════════════════════════════════════════════════════ *)

stressCube[sx_, sy_, txy_, sz_: 0] := Module[{cubeSize = 1, arrows = {}},
  (* Cube *)
  Graphics3D[{
    (* Semi-transparent cube *)
    {Opacity[0.3], EdgeForm[{Thick, Gray}],
     Cuboid[{-cubeSize/2, -cubeSize/2, -cubeSize/2},
            {cubeSize/2, cubeSize/2, cubeSize/2}]},

    (* σ_x arrows (red, along X) *)
    If[Abs[sx] > 0.1,
      {Red, Thick, Arrowheads[0.04 Sign[sx]],
       Arrow[{{-0.8, 0, 0}, {-0.5, 0, 0}}],
       Arrow[{{0.5, 0, 0}, {0.8, 0, 0}}]},
      Nothing],

    (* σ_y arrows (blue, along Y) *)
    If[Abs[sy] > 0.1,
      {Blue, Thick, Arrowheads[0.04 Sign[sy]],
       Arrow[{{0, -0.8, 0}, {0, -0.5, 0}}],
       Arrow[{{0, 0.5, 0}, {0, 0.8, 0}}]},
      Nothing],

    (* τ_xy arrows (green, tangential) *)
    If[Abs[txy] > 0.1,
      {Darker[Green], Thick,
       Arrow[{{0.5, -0.3, 0}, {0.5, 0.3, 0}}],
       Arrow[{{-0.5, 0.3, 0}, {-0.5, -0.3, 0}}],
       Arrow[{{-0.3, 0.5, 0}, {0.3, 0.5, 0}}],
       Arrow[{{0.3, -0.5, 0}, {-0.3, -0.5, 0}}]},
      Nothing],

    (* Labels *)
    Text[Style["\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\)", 14, Red], {0.95, 0, 0}],
    Text[Style["\!\(\*SubscriptBox[\(\[Sigma]\), \(y\)]\)", 14, Blue], {0, 0.95, 0}],
    If[Abs[txy] > 0.1,
      Text[Style["\!\(\*SubscriptBox[\(\[Tau]\), \(xy\)]\)", 12, Darker[Green]], {0.6, 0.6, 0}],
      Nothing]
  },
    Boxed -> False, ViewPoint -> {2.5, 1.5, 1.5},
    ImageSize -> 280, Lighting -> "Neutral"
  ]
];

(* ══════════════════════════════════════════════════════════════════
   Mohr's Circle Plot
   ══════════════════════════════════════════════════════════════════ *)

mohrCirclePlot[sx_, sy_, txy_, rotAngle_] := Module[
  {res, c, R, s1, s2, thetaP, rotStress},

  res = mohrCalc[sx, sy, txy];
  c = res["center"]; R = res["R"]; s1 = res["s1"]; s2 = res["s2"];
  thetaP = res["thetaP"];
  rotStress = stressAtAngle[sx, sy, txy, rotAngle * Pi / 180];

  Show[
    (* Circle *)
    Graphics[{
      {LightGray, Thick, Circle[{c, 0}, R]},

      (* Line through X and Y points *)
      {Gray, Dashed, Line[{{sx, -txy}, {sy, txy}}]},

      (* Point X (σ_x, -τ_xy) *)
      {Red, PointSize[Large], Point[{sx, -txy}]},
      Text[Style["X", 11, Red, Bold], {sx, -txy} + {0.02 R, -0.08 R}],

      (* Point Y (σ_y, τ_xy) *)
      {Blue, PointSize[Large], Point[{sy, txy}]},
      Text[Style["Y", 11, Blue, Bold], {sy, txy} + {0.02 R, 0.08 R}],

      (* Principal stress points *)
      {Darker[Green], PointSize[Medium], Point[{s1, 0}], Point[{s2, 0}]},
      Text[Style["\!\(\*SubscriptBox[\(\[Sigma]\), \(1\)]\)", 10, Darker[Green]], {s1, 0} + {0.05 R, 0.08 R}],
      Text[Style["\!\(\*SubscriptBox[\(\[Sigma]\), \(2\)]\)", 10, Darker[Green]], {s2, 0} + {-0.1 R, 0.08 R}],

      (* Center *)
      {Black, PointSize[Small], Point[{c, 0}]},

      (* Rotated state point *)
      {Magenta, PointSize[Medium],
       Point[{rotStress[[1]], -rotStress[[2]]}]},
      Text[Style["\[Theta]", 10, Magenta],
       {rotStress[[1]], -rotStress[[2]]} + {0.05 R, 0.05 R}]
    }],
    Axes -> True,
    AxesLabel -> {"Normal Stress \[Sigma] (MPa)", "Shear Stress \[Tau] (MPa)"},
    PlotLabel -> "Mohr's Circle",
    PlotRange -> {{c - 1.5 R, c + 1.5 R}, {-1.5 R, 1.5 R}},
    AspectRatio -> 1,
    ImageSize -> 420
  ]
];

(* ══════════════════════════════════════════════════════════════════
   Main Interactive Panel
   ══════════════════════════════════════════════════════════════════ *)
MechSimMohr[] := Manipulate[
  Module[{res, vm, tr, rotStress, yieldS = 250},
    res = mohrCalc[sigmaX, sigmaY, tauXY];
    vm = vonMises2D[res["s1"], res["s2"]];
    tr = tresca[res["s1"], res["s2"]];
    rotStress = stressAtAngle[sigmaX, sigmaY, tauXY, rotAngle * Pi / 180];

    Column[{
      (* Results Panel *)
      Panel[Grid[{
        {Style["Principal Stresses", Bold, 12], SpanFromLeft},
        {"\!\(\*SubscriptBox[\(\[Sigma]\), \(1\)]\)", NumberForm[res["s1"], 4] <> " MPa"},
        {"\!\(\*SubscriptBox[\(\[Sigma]\), \(2\)]\)", NumberForm[res["s2"], 4] <> " MPa"},
        {"\!\(\*SubscriptBox[\(\[Tau]\), \(max\)]\)", NumberForm[res["tmax"], 4] <> " MPa"},
        {"\!\(\*SubscriptBox[\(\[Theta]\), \(p\)]\)", NumberForm[res["thetaP"], 3] <> "\[Degree]"},
        {"", ""},
        {Style["Failure Criteria", Bold, 12], SpanFromLeft},
        {"Von Mises", Style[NumberForm[vm, 4] <> " MPa",
          If[vm > yieldS, Red, Darker[Green]]]},
        {"Tresca", Style[NumberForm[tr, 4] <> " MPa",
          If[tr > yieldS, Red, Darker[Green]]]},
        {"", ""},
        {Style["Rotated State (\[Theta] = " <> ToString[rotAngle] <> "\[Degree])", Bold, 11], SpanFromLeft},
        {"\[Sigma]_n", NumberForm[rotStress[[1]], 4] <> " MPa"},
        {"\[Tau]_nt", NumberForm[rotStress[[2]], 4] <> " MPa"}
      }, Alignment -> Left, Spacings -> {2, 0.3}],
        "Mohr's Circle Results", Background -> LightCyan],

      (* Graphics Row: Circle + Cube *)
      Row[{
        mohrCirclePlot[sigmaX, sigmaY, tauXY, rotAngle],
        Spacer[20],
        stressCube[sigmaX, sigmaY, tauXY]
      }]
    }, Spacings -> 1]
  ],

  {{sigmaX, 80, "\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\) (MPa)"}, -500, 500, 1, Appearance -> "Labeled"},
  {{sigmaY, -40, "\!\(\*SubscriptBox[\(\[Sigma]\), \(y\)]\) (MPa)"}, -500, 500, 1, Appearance -> "Labeled"},
  {{tauXY, 30, "\!\(\*SubscriptBox[\(\[Tau]\), \(xy\)]\) (MPa)"}, -300, 300, 1, Appearance -> "Labeled"},
  Delimiter,
  {{rotAngle, 0, "Rotation Angle \[Theta] (\[Degree])"}, -90, 90, 1, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {sigmaX, sigmaY, tauXY, rotAngle}
]

(* Run: MechSimMohr[] *)
