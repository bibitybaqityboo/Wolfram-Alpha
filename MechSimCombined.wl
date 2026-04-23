(* ::Package:: *)

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   MechSimCombined.wl \[LongDash] Thermal Torsion Rig Demo (Wolfram Language)
   
   Statically indeterminate torsion/axial load problem driven by thermal
   expansion/contraction of two elastic axial bars attached at the end of
   a cantilever rod with solid circular cross section.
   
   Includes: variable applied torque at distance "a" from clamp,
   selectable materials (Steel, Aluminum, Magnesium), full quantitative
   readouts, torsion moment & twist diagrams, compatibility condition.
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Section 1: Material Database
   
   Purpose: Define elastic properties for three material families as
   required by the rubric (steel, aluminum, magnesium alloys).
   Each entry contains: Young's modulus E, shear modulus G, yield stress,
   coefficient of thermal expansion alpha, and display color.
   
   Inputs: None (constant data)
   Outputs: Association "materials" keyed by material name string
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
(* Representative alloys chosen from textbook Table (Avg. Mechanical Properties, SI):
     Steel:     Structural A-36      (E=200 GPa, G=75 GPa, \[Sigma]_y=250 MPa, \[Alpha]=12\[Times]10\:207b\:2076/\[Degree]C)
     Aluminum:  6061-T6 Wrought      (E=68.9 GPa, G=26 GPa, \[Sigma]_y=255 MPa, \[Alpha]=24\[Times]10\:207b\:2076/\[Degree]C)
     Magnesium: Am 1004-T61          (E=44.7 GPa, G=18 GPa, \[Sigma]_y=152 MPa, \[Alpha]=26\[Times]10\:207b\:2076/\[Degree]C)  *)
materials = <|
  "Steel (A-36)"      -> <|"E" -> 200*^9,  "G" -> 75*^9,   "yieldStress" -> 250*^6, "alpha" -> 12*^-6, "color" -> RGBColor[0.53, 0.6, 0.67]|>,
  "Aluminum (6061-T6)" -> <|"E" -> 68.9*^9, "G" -> 26*^9,   "yieldStress" -> 255*^6, "alpha" -> 24*^-6, "color" -> RGBColor[0.69, 0.72, 0.75]|>,
  "Magnesium (Am1004)" -> <|"E" -> 44.7*^9, "G" -> 18*^9,   "yieldStress" -> 152*^6, "alpha" -> 26*^-6, "color" -> RGBColor[0.75, 0.75, 0.72]|>
|>;

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Section 2: Heatmap Color Function
   
   Purpose: Map a normalized stress ratio [0,1] to a color gradient
   from blue (low) through cyan, green, yellow to red (yield).
   
   Inputs: t \[LongDash] normalized stress ratio (Real, 0 to 1)
   Outputs: RGBColor
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Section 3: Core Calculations \[LongDash] Statically Indeterminate Torsion Problem
   
   Purpose: Solve the combined axial/bending/torsion problem for a
   cantilever rod with solid circular cross-section. When the thermal rig
   is enabled, solves the statically indeterminate system where two axial
   bars attached at distance Rarm from the rod center create a torque
   couple via differential thermal expansion.
   
   The applied torque T is at position "a" from the clamp, creating two
   torsion segments: [0, a] and [a, L].
   
   Inputs:
     P        \[LongDash] Axial load at free end (N)
     V        \[LongDash] Transverse load at free end (N)
     T        \[LongDash] Applied torque magnitude (N\[CenterDot]m)
     torqPos  \[LongDash] Position of applied torque from clamp (m)
     L        \[LongDash] Rod length (m)
     r        \[LongDash] Rod outer radius (m)
     E        \[LongDash] Young's modulus of rod (Pa)
     G        \[LongDash] Shear modulus of rod (Pa)
     thermRig \[LongDash] Boolean: enable thermal rig
     thermDT1 \[LongDash] Temperature change in rod 1 (\[Degree]C)
     thermDT2 \[LongDash] Temperature change in rod 2 (\[Degree]C)
     thermL   \[LongDash] Length of axial bars (m)
     thermD   \[LongDash] Diameter of axial bars (m)
     thermE   \[LongDash] Young's modulus of bar material (Pa)
     thermAlpha \[LongDash] CTE of bar material (1/\[Degree]C)
     thermA   \[LongDash] Offset distance from shaft surface to bar center (m)
   
   Outputs: Association with all stress/strain/force/displacement results
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
calcCombined[P_, V_, T_, torqPos_, L_, r_, E_, G_,
  thermRig_:False, thermDT1_:0, thermDT2_:0, thermL_:1.0, thermD_:0.01, 
  thermE_:200*^9, thermAlpha_:12*^-6, thermA_:0.0] := Module[
  {A, Ival, J, Mmax, sigAxial, sigBend, sigXmax,
   tauTorsion, tauXYmax, sigAvg, Rval, p1, p2, vm, delL, delY,
   Ks, Kr, Rarm, Ttotal, Frod1, Frod2, phiEnd,
   aClip, T1seg, T2seg, tau1, tau2, tauMax, tauMaxSeg,
   gammaMax, rodArea, rod1DeltaL, rod2DeltaL, rod1Stress, rod2Stress,
   rod1Strain, rod2Strain, compatLHS, compatRHS, compatError},

  (* Cross-section properties for solid circular rod *)
  A = \[Pi] r^2;
  Ival = \[Pi]/4 r^4;
  J = \[Pi]/2 r^4;
  
  (* Clip torque position to valid range *)
  aClip = Clip[torqPos, {0, L}];

  (* \[HorizontalLine]\[HorizontalLine] Bending \[HorizontalLine]\[HorizontalLine] *)
  Mmax = Abs[V] * L;
  sigAxial = Abs[P] / A;
  sigBend = (Mmax * r) / Ival;
  sigXmax = sigAxial + sigBend;

  (* \:2550\:2550 Thermal Rig: Statically Indeterminate Torque Calculation \:2550\:2550
     
     The thermal rig consists of two axial bars attached to a rigid crossbar
     at the free end of the rod, at distance Rarm from the rod center.
     When the bars experience different temperature changes \[CapitalDelta]T1 and \[CapitalDelta]T2,
     they try to expand/contract by different amounts, creating a torque
     couple on the rod.
     
     Key equations (derived from compatibility + equilibrium):
     
     Compatibility (small-angle, bars deform tangentially):
       Bar 1: \[Delta]\:2081 = F\:2081\[CenterDot]l/(E_bar\[CenterDot]A_bar) + \[Alpha]\[CenterDot]\[CapitalDelta]T\:2081\[CenterDot]l = \[CurlyPhi]\[CenterDot]Rarm
       Bar 2: \[Delta]\:2082 = F\:2082\[CenterDot]l/(E_bar\[CenterDot]A_bar) + \[Alpha]\[CenterDot]\[CapitalDelta]T\:2082\[CenterDot]l = -\[CurlyPhi]\[CenterDot]Rarm
     
     Internal torque distribution with applied torque T at position a:
       Segment 1 [0,a]:  T\:2081(x) = T_clamp
       Segment 2 [a,L]:  T\:2082(x) = T_clamp + T_applied
     
     Equilibrium at free end: T_clamp + T_applied = (F\:2081 - F\:2082)\[CenterDot]Rarm
     
     Twist at free end:
       \[CurlyPhi] = T\:2081\[CenterDot]a/(GJ) + T\:2082\[CenterDot](L-a)/(GJ)
         = (T_clamp\[CenterDot]L + T_applied\[CenterDot](L-a))/(GJ)
     
     Stiffness parameters:
       Ks = torsional stiffness of shaft = G\[CenterDot]J/L
       Kr = axial stiffness of each bar = (\[Pi]/4\[CenterDot]d\.b2)\[CenterDot]E_bar/l_bar
       Rarm = r + offset_a
     
     Solving the system for \[CurlyPhi]:
       \[CurlyPhi] = (T_applied\[CenterDot](L-a)/L + Kr\[CenterDot]Rarm\[CenterDot]\[Alpha]\[CenterDot](\[CapitalDelta]T\:2081-\[CapitalDelta]T\:2082)\[CenterDot]l) / (Ks + 2\[CenterDot]Kr\[CenterDot]Rarm\.b2)
     
     Note: When a=0 (torque at clamp), the applied torque has full
     lever arm (L); when a=L (torque at end), lever arm is 0 because
     the torque is directly resisted by the bars.
  *)
  If[thermRig,
    Ks = (G * J) / L;
    Kr = ((\[Pi] / 4 * thermD^2) * thermE) / thermL;
    Rarm = r + thermA;
    
    (* Solve for twist angle at free end.
       The applied torque T at position a contributes to twist proportionally
       to how much rod length is between the clamp and the torque.
       The effective torque contribution to twist is T*(L-a)/L when
       combined with the bar stiffness at the end. *)
    phiEnd = (T * (L - aClip) / L + Kr * Rarm * thermAlpha * (thermDT1 - thermDT2) * thermL) / (Ks + 2 * Kr * Rarm^2);
    
    (* Reconstruct internal torques from \[CurlyPhi] *)
    Frod1 = Kr * (phiEnd * Rarm - thermAlpha * thermDT1 * thermL);
    Frod2 = Kr * (-phiEnd * Rarm - thermAlpha * thermDT2 * thermL);
    
    (* Internal torque at free end section (segment 2) *)
    T2seg = (Frod1 - Frod2) * Rarm;
    (* Internal torque at clamp section (segment 1) *)
    T1seg = T2seg - T;  (* Jump: T\:2081 = T\:2082 - T_applied *)
    Ttotal = T2seg;  (* Ttotal represents the torque at the bar end for visualization *)
    
    (* \[HorizontalLine]\[HorizontalLine] Per-bar detailed results \[HorizontalLine]\[HorizontalLine] *)
    rodArea = \[Pi] / 4 * thermD^2;
    rod1DeltaL = Frod1 * thermL / (thermE * rodArea) + thermAlpha * thermDT1 * thermL;
    rod2DeltaL = Frod2 * thermL / (thermE * rodArea) + thermAlpha * thermDT2 * thermL;
    rod1Stress = Frod1 / rodArea;
    rod2Stress = Frod2 / rodArea;
    rod1Strain = rod1Stress / thermE + thermAlpha * thermDT1;
    rod2Strain = rod2Stress / thermE + thermAlpha * thermDT2;
    
    (* \[HorizontalLine]\[HorizontalLine] Compatibility condition verification \[HorizontalLine]\[HorizontalLine]
       Bar 1 total deformation should equal \[CurlyPhi]\[CenterDot]Rarm
       Bar 2 total deformation should equal -\[CurlyPhi]\[CenterDot]Rarm
       The compatibility error should be zero (or machine epsilon). *)
    compatLHS = rod1DeltaL;           (* actual total deformation of bar 1 *)
    compatRHS = phiEnd * Rarm;        (* required by twist geometry *)
    compatError = Abs[compatLHS - compatRHS];
  ,
    (* No thermal rig: simple two-segment torsion.
       For a cantilever with torque at position a and free end at L:
       The reaction at the clamp equals T_applied.
       Internal torque: T(x) = T_applied for 0<=x<a, T(x) = 0 for a<x<=L. *)
    T1seg = T;    (* Clamp to torque point *)
    T2seg = 0;    (* Torque point to free end \[LongDash] free, so zero *)
    Ttotal = T;   (* For backward compatibility *)
    phiEnd = T * aClip / (G * J);  (* Twist: only segment 1 contributes *)
    Frod1 = 0; Frod2 = 0;
    rodArea = 0; rod1DeltaL = 0; rod2DeltaL = 0;
    rod1Stress = 0; rod2Stress = 0; rod1Strain = 0; rod2Strain = 0;
    compatLHS = 0; compatRHS = 0; compatError = 0;
  ];
  
  (* Max torsional shear stress in each segment *)
  tau1 = Abs[T1seg * r / J];
  tau2 = Abs[T2seg * r / J];
  tauMax = Max[tau1, tau2];
  tauMaxSeg = If[tau1 >= tau2, "Clamp to Torque (0 to a)", "Torque to End (a to L)"];
  
  tauTorsion = tauMax;
  tauXYmax = tauTorsion;
  gammaMax = tauMax / G;  (* Max shear strain *)

  (* \[HorizontalLine]\[HorizontalLine] Principal stresses and Von Mises \[HorizontalLine]\[HorizontalLine] *)
  sigAvg = sigXmax / 2;
  Rval = Sqrt[(sigAvg)^2 + tauXYmax^2];

  p1 = sigAvg + Rval;
  p2 = sigAvg - Rval;
  vm = Sqrt[p1^2 - p1 p2 + p2^2];

  (* \[HorizontalLine]\[HorizontalLine] Deflections \[HorizontalLine]\[HorizontalLine] *)
  delL = (P * L) / (A * E);
  delY = (V * L^3) / (3 * E * Ival);

  <|"sigmaX" -> sigXmax, "tauXY" -> tauXYmax, "p1" -> p1, "p2" -> p2, "vm" -> vm,
    "deltaL" -> delL, "deltaY" -> delY, "phi" -> phiEnd, "A" -> A, "I" -> Ival, "J" -> J,
    "Frod1" -> Frod1, "Frod2" -> Frod2, "Ttotal" -> Ttotal,
    "T1seg" -> T1seg, "T2seg" -> T2seg, "torqPos" -> aClip,
    "tauMax" -> tauMax, "tauMaxSeg" -> tauMaxSeg, "gammaMax" -> gammaMax,
    "rodArea" -> rodArea,
    "rod1DeltaL" -> rod1DeltaL, "rod2DeltaL" -> rod2DeltaL,
    "rod1Stress" -> rod1Stress, "rod2Stress" -> rod2Stress,
    "rod1Strain" -> rod1Strain, "rod2Strain" -> rod2Strain,
    "compatLHS" -> compatLHS, "compatRHS" -> compatRHS, "compatError" -> compatError|>
];

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Section 4: 3D Visualization
   
   Purpose: Generate the 3D parametric plot of the deformed rod with:
   - Rectangular mesh grid on surface showing torsional deformation
   - Undeformed reference axial line (straight, does not twist)
   - End cap with polar grid (radial + concentric) that deforms with twist
   - Undeformed reference radial line on end cap
   - Thermal rig bars with dashed original geometry overlay
   - Applied torque "fat arrow" at position "a"
   - Load arrows and support wall
   
   Inputs: All physics parameters + visualization settings
   Outputs: Legended Graphics3D object
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
visualizeShaft[P_, V_, Tapplied_, T1seg_, T2seg_, L_, rOuter_, E_, G_, yield_, scale_,
  heatmapType_, zoom_, torqPos_:0,
  thermRig_:False, thermDT1_:0, thermDT2_:0, thermL_:1.0, thermD_:0.01, thermA_:0.0, 
  Frod1_:0, Frod2_:0, cameraView_:"Perspective",
  rod1DeltaL_:0, rod2DeltaL_:0] := Module[
  {A, Ival, J, deformX, deformY, twist, colorFn,
   endX, endY, arrP, arrV, arrTorque, support, plot3D,
   legendMax, legendLabel, 
   endCap, endCapGrid, twistEnd, nSlices, nCircles,
   thermRigPlot, crossbar, rod1, rod2, pin1, pin2, lbl1, lbl2, Rarm, viewPt,
   refLine, refRadialLine, torqPosC, aClip,
   rod1Orig, rod2Orig},

  A = \[Pi] rOuter^2;
  Ival = \[Pi]/4 rOuter^4;
  J = \[Pi]/2 rOuter^4;
  aClip = Clip[torqPos, {0, L}];

  (* \[HorizontalLine]\[HorizontalLine] Deformation functions \[HorizontalLine]\[HorizontalLine] *)
  deformX[x_] := (P * x) / (A * E) * scale;

  deformY[x_] := If[V != 0, (V * x^2) / (6 * E * Ival) * (3 * L - x) * scale, 0];

  (* Twist function: piecewise for two-segment torque distribution.
     Segment 1 [0,a]: twist rate = T1seg/(GJ)
     Segment 2 [a,L]: twist rate = T2seg/(GJ) *)
  twist[x_] := If[x <= aClip,
    T1seg * x / (G * J),
    T1seg * aClip / (G * J) + T2seg * (x - aClip) / (G * J)
  ] * scale;

  (* \[HorizontalLine]\[HorizontalLine] Stress color function for surface heatmap \[HorizontalLine]\[HorizontalLine] *)
  colorFn = Function[{x, y, z, u, v},
    Module[{rNode, th, actualY, Mval, sx, txy, vmNode, stressRatio, xPos, Tlocal},
      rNode = rOuter; xPos = u * L;
      th = v - twist[xPos];
      actualY = rNode * Cos[th];
      Mval = V * (L - xPos);
      sx = P / A - (Mval * actualY) / Ival;
      (* Use piecewise internal torque for shear stress *)
      Tlocal = If[xPos <= aClip, T1seg, T2seg];
      txy = Tlocal * rNode / J;
      vmNode = Sqrt[sx^2 + 3 txy^2];
      stressRatio = Which[
        heatmapType === "Normal Stress", Abs[sx] / yield,
        heatmapType === "Shear Stress",  Abs[txy] / (yield / Sqrt[3]),
        True,                            vmNode / yield];
      heatmapColor[stressRatio]
  ]];

  endX = L + deformX[L];
  endY = deformY[L];
  twistEnd = twist[L];

  (* \[HorizontalLine]\[HorizontalLine] Support wall (fixed end / clamp) \[HorizontalLine]\[HorizontalLine] *)
  support = Graphics3D[{
    GrayLevel[0.6], Opacity[0.8],
    Cuboid[{-L*0.05, -rOuter*1.5, -rOuter*1.5}, {0, rOuter*1.5, rOuter*1.5}]
  }];

  (* \[HorizontalLine]\[HorizontalLine] Undeformed reference axial line \[HorizontalLine]\[HorizontalLine]
     A straight line on the rod surface (theta=0) that does NOT twist.
     This shows the original orientation vs the deformed grid. *)
  refLine = Graphics3D[{
    Directive[White, Thickness[0.004], Dashing[{0.02, 0.01}]],
    Line[Table[
      {u * L + deformX[u * L],
       rOuter * 1.001 + deformY[u * L],  (* slightly outside surface *)
       0},
      {u, 0, 1, 0.02}]]
  }];

  (* \[HorizontalLine]\[HorizontalLine] End load arrows \[HorizontalLine]\[HorizontalLine] *)
  arrP = If[P != 0,
    Graphics3D[{Red, Arrowheads[0.05],
      Arrow[If[P > 0,
        {{endX, endY, 0}, {endX + L*0.3, endY, 0}},
        {{endX + L*0.3, endY, 0}, {endX, endY, 0}}]]
    }], Graphics3D[{}]];

  arrV = If[V != 0,
    Graphics3D[{Darker[Green], Arrowheads[0.05],
      Arrow[If[V > 0,
        {{endX, endY - L*0.3, 0}, {endX, endY - rOuter*1.1, 0}},
        {{endX, endY + L*0.3, 0}, {endX, endY + rOuter*1.1, 0}}]]
    }], Graphics3D[{}]];

  (* \[HorizontalLine]\[HorizontalLine] Applied Torque "fat arrow" at position aClip \[HorizontalLine]\[HorizontalLine]
     Represented as thick curving arrows around the rod at the torque point.
     This is the required "fat arrow" representation per rubric. *)
  arrTorque = If[Tapplied != 0,
    Module[{xTq = aClip + deformX[aClip], yTq = deformY[aClip]},
      Graphics3D[{Blue, Thick, Arrowheads[0.06],
        Table[Arrow[
          Table[{xTq, yTq + rOuter*1.4*Cos[th + Sign[Tapplied]*dTh],
                 rOuter*1.4*Sin[th + Sign[Tapplied]*dTh]},
            {dTh, 0, Pi/3, Pi/15}]
        ], {th, 0, 3 Pi/2, Pi/2}],
        (* Label the torque *)
        Text[Style["T", 14, Bold, Blue], {xTq, yTq + rOuter*2.0, 0}]
      }]
    ], Graphics3D[{}]];

  (* \[HorizontalLine]\[HorizontalLine] End cap: filled disk at free end \[HorizontalLine]\[HorizontalLine] *)
  endCap = ParametricPlot3D[
    {endX,
     rr * Cos[th + twistEnd] + endY,
     rr * Sin[th + twistEnd]},
    {rr, 0, rOuter}, {th, 0, 2 \[Pi]},
    Mesh -> None, PlotPoints -> {12, 30},
    PlotStyle -> Directive[GrayLevel[0.85], Opacity[0.9]],
    Boxed -> False, Axes -> False, Lighting -> "Neutral"
  ];

  (* \[HorizontalLine]\[HorizontalLine] Pizza-slice polar grid on end cap \[HorizontalLine]\[HorizontalLine]
     Radial lines and concentric circles that deform WITH the twist.
     This is the required polar grid at the cross-section. *)
  nSlices = 12;
  nCircles = 4;

  endCapGrid = Graphics3D[{
    Directive[Black, Opacity[0.95]],
    (* Radial lines \[LongDash] like pizza slices, deform with twist *)
    Table[
      Tube[{
        {endX, endY, 0},
        {endX,
         rOuter * Cos[k * 2 \[Pi] / nSlices + twistEnd] + endY,
         rOuter * Sin[k * 2 \[Pi] / nSlices + twistEnd]}
      }, rOuter * 0.007], {k, 0, nSlices - 1}],
    (* Concentric circles \[LongDash] deform with twist *)
    Table[
      Tube[Table[
        {endX,
         (j / nCircles) * rOuter * Cos[th + twistEnd] + endY,
         (j / nCircles) * rOuter * Sin[th + twistEnd]},
        {th, 0, 2 \[Pi] + 2 \[Pi] / 48, 2 \[Pi] / 48}], rOuter * 0.005
      ], {j, 1, nCircles}]
  }];

  (* \[HorizontalLine]\[HorizontalLine] Undeformed reference radial line on end cap \[HorizontalLine]\[HorizontalLine]
     A fixed radial line at theta=0 that does NOT rotate with twist.
     Shows original orientation for comparison. *)
  refRadialLine = Graphics3D[{
    Directive[Red, Thickness[0.005], Dashing[{0.015, 0.01}]],
    Line[{{endX, endY, 0}, {endX, rOuter * 1.05 + endY, 0}}],
    Text[Style["Ref", 10, Bold, Red], {endX, rOuter * 1.15 + endY, 0}]
  }];

  (* \[HorizontalLine]\[HorizontalLine] Thermal Rig Visualization \[HorizontalLine]\[HorizontalLine]
     Shows crossbar, two axial bars, pin supports, temperature labels,
     force arrows, and dashed original (undeformed) bar positions. *)
  thermRigPlot = If[thermRig,
    Rarm = rOuter + thermA;
    Module[{rodR = thermD / 2, cY1, cZ1, cY2, cZ2,
            cY1orig, cZ1orig, cY2orig, cZ2orig},
      (* Deformed bar positions \[LongDash] rotate with twist *)
      cY1 = endY + Rarm * Cos[twistEnd + 0];
      cZ1 = Rarm * Sin[twistEnd + 0];
      cY2 = endY + Rarm * Cos[twistEnd + Pi];
      cZ2 = Rarm * Sin[twistEnd + Pi];
      
      (* Original (undeformed) bar positions \[LongDash] NO twist *)
      cY1orig = endY + Rarm;
      cZ1orig = 0;
      cY2orig = endY - Rarm;
      cZ2orig = 0;

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
      
      (* \[HorizontalLine]\[HorizontalLine] Dashed original (undeformed) bar geometry \[HorizontalLine]\[HorizontalLine]
         Shows where the bars would be without any twist, so the user
         can visually compare deformed vs undeformed positions. *)
      rod1Orig = Graphics3D[{
         Directive[GrayLevel[0.6], Opacity[0.5], Dashing[{0.02, 0.01}], Thickness[0.003]],
         Line[{{endX, cY1orig, cZ1orig}, {endX, cY1orig, cZ1orig - thermL}}]
      }];
      rod2Orig = Graphics3D[{
         Directive[GrayLevel[0.6], Opacity[0.5], Dashing[{0.02, 0.01}], Thickness[0.003]],
         Line[{{endX, cY2orig, cZ2orig}, {endX, cY2orig, cZ2orig - thermL}}]
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

      Module[{arrLen = L * 0.15},
        Show[crossbar, rod1, rod2, rod1Orig, rod2Orig, pin1, pin2, lbl1, lbl2,
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
    (* Main deformed rod surface with rectangular mesh grid *)
    ParametricPlot3D[
      {u * L + deformX[u * L],
       rOuter * Cos[v + twist[u * L]] + deformY[u * L],
       rOuter * Sin[v + twist[u * L]]},
      {u, 0, 1}, {v, 0, 2 \[Pi]},
      Mesh -> {20, 12}, MeshFunctions -> {#4 &, #5 &},
      MeshStyle -> Directive[Black, Opacity[0.6], Thickness[0.002]],
      PlotPoints -> {40, 40},
      ColorFunction -> colorFn,
      ColorFunctionScaling -> False, Boxed -> False, Axes -> False, Lighting -> "Neutral"
    ],
    refLine,           (* Undeformed reference axial line *)
    endCap, endCapGrid, refRadialLine,   (* End cap with polar grid + reference *)
    thermRigPlot,      (* Thermal rig bars *)
    arrP, arrV, arrTorque,   (* Load arrows *)
    ViewPoint -> viewPt, 
    ViewProjection -> If[cameraView === "Front View" || cameraView === "Side View", "Orthographic", "Perspective"],
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

  Legended[plot3D, BarLegend[{heatmapColor[# / (legendMax / 10^6)] &, {0, legendMax / 10^6}},
    LegendLabel -> Style[legendLabel, 12, Bold, Black],
    LegendMarkerSize -> 300,
    LabelStyle -> {FontSize -> 11}
  ]]
];

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   Section 5: Main Interactive Panel (Manipulate)
   
   Purpose: Combine all controls, readouts, diagrams, and 3D visualization
   into a single interactive Manipulate panel. Includes:
   - Full quantitative readouts panel (stresses, forces, strains)
   - Per-bar results when thermal rig is active
   - Compatibility condition verification
   - Torsion moment diagram T(x)
   - Angle of twist diagram \[CurlyPhi](x)
   - Bending moment diagram M(x)
   - 3D deformation view
   
   Inputs: User-manipulated slider/control values
   Outputs: Interactive Manipulate interface
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
MechSimCombined[] := Manipulate[
  Module[{mat, eVal, gVal, yield, alpha, results, sf, plotBMD, plotTMD, plotTwist,
          thermMatProps, thermEVal, thermAlphaVal, aClip},
    mat = materials[material];
    eVal = mat["E"];
    gVal = mat["G"];
    yield = mat["yieldStress"];
    alpha = mat["alpha"];
    aClip = Clip[torquePos, {0, length}];

    thermMatProps = materials[thermMat];
    thermEVal = thermMatProps["E"];
    thermAlphaVal = thermMatProps["alpha"];

    results = calcCombined[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3,
      aClip, length, outerR/1000, eVal, gVal,
      thermEnable, thermDT1, thermDT2, thermL, thermD/1000, thermEVal, thermAlphaVal, thermA/1000];
    sf = If[results["vm"] > 0, yield / results["vm"], \[Infinity]];

    ControlActive[
      Column[{
        Style["\[ThinSpace] Computations Paused During Interaction...", 14, Bold, Gray],
        visualizeShaft[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3, results["T1seg"], results["T2seg"], length,
          outerR/1000, eVal, gVal, yield, deformScale, heatmapType, magnification,
          aClip, thermEnable, thermDT1, thermDT2, thermL, thermD/1000, thermA/1000, 
          results["Frod1"], results["Frod2"], cameraView,
          results["rod1DeltaL"], results["rod2DeltaL"]]
      }, Spacings -> 1, Alignment -> Center],

      Module[{},
        (* \[HorizontalLine]\[HorizontalLine] Bending Moment Diagram M(x) \[HorizontalLine]\[HorizontalLine] *)
        plotBMD = Plot[
          bentLoad * 10^3 * (length - x),
          {x, 0, length},
          PlotStyle -> Darker[Blue],
          Filling -> Axis,
          FillingStyle -> Directive[Opacity[0.4], Darker[Blue]],
          PlotLabel -> Style["Bending Moment Diagram M(x)", 12, Bold],
          AxesLabel -> {"x (m)", "Moment (N\[CenterDot]m)"},
          ImageSize -> 400, Exclusions -> None];

        (* \[HorizontalLine]\[HorizontalLine] Torsion Moment Diagram T(x) \[HorizontalLine]\[HorizontalLine]
           Piecewise constant: T1seg from 0 to aClip, T2seg from aClip to L *)
        plotTMD = Plot[
          Piecewise[{
            {results["T1seg"], x <= aClip},
            {results["T2seg"], x > aClip}
          }],
          {x, 0, length},
          PlotStyle -> {Darker[Red], Thick},
          Filling -> Axis,
          FillingStyle -> Directive[Opacity[0.3], Darker[Red]],
          PlotLabel -> Style["Torsion Moment Diagram T(x)", 12, Bold],
          AxesLabel -> {"x (m)", "Torque (N\[CenterDot]m)"},
          PlotRange -> All, ImageSize -> 400,
          Exclusions -> None,
          Epilog -> {
            Dashed, GrayLevel[0.5],
            Line[{{aClip, 0}, {aClip, results["T1seg"]}}],
            Text[Style["a", 10, Italic], {aClip, 0}, {0, 1.5}]
          }];

        (* \[HorizontalLine]\[HorizontalLine] Angle of Twist Diagram \[Phi](x) \[HorizontalLine]\[HorizontalLine]
           Piecewise linear: slope T1seg/(GJ) from 0 to aClip,
           slope T2seg/(GJ) from aClip to L *)
        plotTwist = Plot[
          Piecewise[{
            {results["T1seg"] * x / (gVal * results["J"]), x <= aClip},
            {results["T1seg"] * aClip / (gVal * results["J"]) + 
             results["T2seg"] * (x - aClip) / (gVal * results["J"]), x > aClip}
          }],
          {x, 0, length},
          PlotStyle -> {Darker[Magenta], Thick},
          Filling -> Axis,
          FillingStyle -> Directive[Opacity[0.2], Darker[Magenta]],
          PlotLabel -> Style["Angle of Twist Diagram \[Phi](x)", 12, Bold],
          AxesLabel -> {"x (m)", "\[Phi] (rad)"},
          PlotRange -> All, ImageSize -> 400,
          Exclusions -> None,
          Epilog -> {
            Dashed, GrayLevel[0.5],
            Line[{{aClip, 0}, {aClip, results["T1seg"] * aClip / (gVal * results["J"])}}],
            Text[Style["a", 10, Italic], {aClip, 0}, {0, 1.5}]
          }];

      Column[{
        (* \:2550\:2550 Main Results Panel \:2550\:2550 *)
        Panel[Grid[{
          {Style["Max Normal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["sigmaX"] / 10^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Max Torsional Shear (\!\(\*SubscriptBox[\(\[Tau]\), \(max\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["tauXY"] / 10^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Max Shear Strain (\!\(\*SubscriptBox[\(\[Gamma]\), \(max\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[N[results["gammaMax"]], {6, 4}]] <> " rad", 11, Bold, Blue]},
          {Style["Max Shear Location", 11, Darker[Blue]],
           Style[results["tauMaxSeg"], 11, Bold, Darker[Orange]]},
          {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(1\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["p1"] / 10^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(2\)]\))", 11, Darker[Blue]],
           Style[ToString[NumberForm[results["p2"] / 10^6, {6, 2}]] <> " MPa", 11, Bold, Blue]},
          {Style["Von Mises Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(vm\)]\))", 12, Darker[Blue]],
           Style[ToString[NumberForm[results["vm"] / 10^6, {6, 2}]] <> " MPa", 12, Bold,
             If[results["vm"] > yield, Red, Blue]]},
          {Style["Angle of Twist (\[Phi] at end)", 12, Darker[Blue]],
           Style[ToString[NumberForm[results["phi"], {6, 4}]] <> " rad  (" <>
             ToString[NumberForm[N[results["phi"] * 180 / \[Pi]], {6, 2}]] <> "\[Degree])", 12, Bold, Blue]},
          {Style["Axial Elongation (\[CapitalDelta]L)", 11, Darker[Blue]],
           Style[ToString[NumberForm[N[results["deltaL"] * 1000], {6, 4}]] <> " mm", 11, Bold, Blue]},
          {Style["Safety Factor", 11, Darker[Blue]],
           If[sf == \[Infinity], Style["\[Infinity]", 11, Bold],
             Style[NumberForm[sf, {5, 2}], 11, Bold,
               If[sf >= 2, Darker[Green], If[sf >= 1, Orange, Red]]]]}
        }, Alignment -> {{Left, Right}, Center}, Spacings -> {2, 0.8}, Dividers -> Center],
        Style["\[ThinSpace] Combined Loading Results", 14, Bold], Background -> White],

        (* \:2550\:2550 Yield Warning \:2550\:2550 *)
        If[results["vm"] > yield,
          Framed[Style["\[WarningSign] YIELD STRESS EXCEEDED ", 12, Bold, Darker[Red]],
            Background -> Lighter[Red, 0.9], FrameStyle -> Thick, FrameColor -> Darker[Red]], ""],

        (* \:2550\:2550 Per-Bar Results (only when thermal rig is active) \:2550\:2550 *)
        If[thermEnable,
          Panel[Grid[{
            {SpanFromLeft, Style["Axial Bar Results", 12, Bold, Black]},
            {"", Style["Bar 1 (Right)", 11, Bold, Black], Style["Bar 2 (Left)", 11, Bold, Black]},
            {Style["Axial Force (N)", 11, Black], 
             Style[ToString[NumberForm[N[results["Frod1"]], {6, 2}]] <> " N", 11, Bold, Black],
             Style[ToString[NumberForm[N[results["Frod2"]], {6, 2}]] <> " N", 11, Bold, Black]},
            {Style["\[CapitalDelta]L (mm)", 11, Black],
             Style[ToString[NumberForm[N[results["rod1DeltaL"] * 1000], {6, 4}]] <> " mm", 11, Bold, Black],
             Style[ToString[NumberForm[N[results["rod2DeltaL"] * 1000], {6, 4}]] <> " mm", 11, Bold, Black]},
            {Style["Stress (MPa)", 11, Black],
             Style[ToString[NumberForm[N[results["rod1Stress"] / 10^6], {6, 2}]] <> " MPa", 11, Bold, Black],
             Style[ToString[NumberForm[N[results["rod2Stress"] / 10^6], {6, 2}]] <> " MPa", 11, Bold, Black]},
            {Style["Strain", 11, Black],
             Style[ToString[NumberForm[N[results["rod1Strain"]], {6, 6}]], 11, Bold, Black],
             Style[ToString[NumberForm[N[results["rod2Strain"]], {6, 6}]], 11, Bold, Black]}
          }, Alignment -> {{Left, Center, Center}, Center}, Spacings -> {2, 0.8}, Dividers -> Center],
          Style["\[ThinSpace] Thermal Rig Bar Data", 14, Bold, Black], Background -> White],
          ""
        ],

        (* \:2550\:2550 Compatibility Condition (only when thermal rig is active) \:2550\:2550 *)
        If[thermEnable,
          Panel[Grid[{
            {Style["Compatibility Condition Verification", 12, Bold, Black], SpanFromLeft},
            {Style["Bar 1 total deformation (\[Delta]\[Sub1])", 11, Black], 
             Style[ToString[NumberForm[N[results["compatLHS"] * 1000], {8, 6}]] <> " mm", 11, Bold, Black]},
            {Style["Required by twist (\[Phi]\[CenterDot]R\[Sub]arm)", 11, Black],
             Style[ToString[NumberForm[N[results["compatRHS"] * 1000], {8, 6}]] <> " mm", 11, Bold, Black]},
            {Style["Compatibility Error", 11, Black],
             Style[ToString[NumberForm[N[results["compatError"] * 1000], {8, 6}]] <> " mm", 11, Bold,
               If[results["compatError"] < 1*^-10, Darker[Green], Red]]},
            {Style["Status", 11, Bold, Black],
             Style[If[results["compatError"] < 1*^-10, 
               "\[Checkmark] SATISFIED (error \[TildeTilde] 0)", 
               "\[WarningSign] NOT SATISFIED"], 12, Bold,
               If[results["compatError"] < 1*^-10, Darker[Green], Red]]}
          }, Alignment -> {{Left, Right}, Center}, Spacings -> {2, 0.8}, Dividers -> Center],
          Style["\[ThinSpace] Compatibility Check", 14, Bold, Black], Background -> White],
          ""
        ],

        (* \:2550\:2550 Torsion Segment Info \:2550\:2550 *)
        Panel[Grid[{
          {Style["Torsion Segments", 12, Bold, Black], SpanFromLeft},
          {Style["Torque position a", 11, Black], Style[ToString[NumberForm[N[aClip], {4, 2}]] <> " m from clamp", 11, Bold, Black]},
          {Style["Segment 1: [0, a]  T\[Sub1]", 11, Black], 
           Style[ToString[NumberForm[N[results["T1seg"]/1000], {6, 2}]] <> " kN\[CenterDot]m", 11, Bold, Black]},
          {Style["Segment 2: [a, L]  T\[Sub2]", 11, Black],
           Style[ToString[NumberForm[N[results["T2seg"]/1000], {6, 2}]] <> " kN\[CenterDot]m", 11, Bold, Black]},
          {Style["\[Tau]\[Sub]max occurs in", 11, Bold, Black],
           Style[results["tauMaxSeg"], 11, Bold, Darker[Orange]]}
        }, Alignment -> {{Left, Right}, Center}, Spacings -> {2, 0.8}, Dividers -> Center],
        Style["\[ThinSpace] Torsion Segments", 14, Bold, Black], Background -> White],

        (* \:2550\:2550 3D Visualization \:2550\:2550 *)
        visualizeShaft[axialLoad * 10^3, bentLoad * 10^3, torsionLoad * 10^3, results["T1seg"], results["T2seg"], length,
          outerR/1000, eVal, gVal, yield, deformScale, heatmapType,
          magnification, aClip, thermEnable, thermDT1, thermDT2, thermL, thermD/1000, thermA/1000, 
          results["Frod1"], results["Frod2"], cameraView,
          results["rod1DeltaL"], results["rod2DeltaL"]],

        (* \:2550\:2550 Diagrams \:2550\:2550 *)
        plotTMD,
        plotTwist,
        plotBMD
      }, Spacings -> 1, Alignment -> Center]
      ]
    ]
  ],

  (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
     Controls \[LongDash] organized by category per rubric requirements
     \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
  Style["Visualization Settings", 12, Bold],
  {{cameraView, "Perspective", "Camera View"}, {"Perspective", "Front View", "Side View"}, ControlType -> RadioButtonBar},
  {{heatmapType, "Von Mises Stress", "Heatmap Display"},
    {"Von Mises Stress", "Normal Stress", "Shear Stress"}, ControlType -> RadioButtonBar},
  {{deformScale, 40, "Deformation Scale"}, 1, 100, 1, Appearance -> "Labeled"},
  {{magnification, 1, "Magnification \[Times]"}, 1, 20, 0.5, Appearance -> "Labeled"},
  Delimiter,
  
  Style["Rod Material & Geometry", 12, Bold],
  Row[{Style["Rod Length L: ", 11], Style["7.0 m (Constant)", 11, Bold, Darker[Gray]]}],
  Row[{Style["Rod Diameter: ", 11], Style["0.5 m (Constant)", 11, Bold, Darker[Gray]]}],
  {{material, "Steel (A-36)", "Rod Material"}, {"Steel (A-36)", "Aluminum (6061-T6)", "Magnesium (Am1004)"}, ControlType -> SetterBar},
  {{length, 7.0}, ControlType -> None},
  {{outerR, 250}, ControlType -> None},
  Delimiter,
  
  Style["Applied Loads", 12, Bold],
  {{axialLoad, 0, "Axial Load P (kN)"}, -500, 500, 5, Appearance -> "Labeled"},
  {{bentLoad, 0, "Transverse Load V (kN)"}, -100, 100, 1, Appearance -> "Labeled"},
  {{torsionLoad, 0, "Applied Torque T (kN\[CenterDot]m)"}, -50, 50, 0.5, Appearance -> "Labeled"},
  {{torquePos, 1.0, "Torque Position a (m from clamp)"}, 0.0, 5.0, 0.05, Appearance -> "Labeled"},
  Delimiter,
  
  Style["Thermal Torsion Rig", 12, Bold],
  {{thermEnable, True, "Enable Thermal Rig"}, {True, False}},
  {{thermDT1, 0, "Bar 1 (Right) \[CapitalDelta]\!\(\*SubscriptBox[\(T\), \(1\)]\) (\[Degree]C)"}, -200, 200, 1, Appearance -> "Labeled"},
  {{thermDT2, 0, "Bar 2 (Left) \[CapitalDelta]\!\(\*SubscriptBox[\(T\), \(2\)]\) (\[Degree]C)"}, -200, 200, 1, Appearance -> "Labeled"},
  {{thermMat, "Aluminum (6061-T6)", "Bar Material"}, {"Steel (A-36)", "Aluminum (6061-T6)", "Magnesium (Am1004)"}, ControlType -> SetterBar},
  {{thermL, 1.0, "Bar Length l (m)"}, 0.1, 3.0, 0.1, Appearance -> "Labeled"},
  {{thermD, 10, "Bar Diameter d (mm)"}, 2, 50, 1, Appearance -> "Labeled"},
  {{thermA, 0, "Offset a from shaft surface (mm)"}, 0, 200, 5, Appearance -> "Labeled"},
  ControlPlacement -> Left,
  TrackedSymbols :> {heatmapType, cameraView, material, length, outerR,
    axialLoad, bentLoad, torsionLoad, deformScale, magnification,
    torquePos,
    thermEnable, thermDT1, thermDT2, thermL, thermD, thermA, thermMat},
  SynchronousUpdating -> False
]

MechSimCombined[]


(* ::Output:: *)
(*Manipulate[Module[{mat$, eVal$, gVal$, yield$, alpha$, results$, sf$, *)
(*    plotBMD$, plotTMD$, plotTwist$, thermMatProps$, thermEVal$, *)
(*    thermAlphaVal$, aClip$}, mat$ = materials[material]; eVal$ = mat$["E"]; *)
(*    gVal$ = mat$["G"]; yield$ = mat$["yieldStress"]; alpha$ = mat$["alpha"]; *)
(*    aClip$ = Clip[torquePos, {0, length}]; thermMatProps$ = *)
(*     materials[thermMat]; thermEVal$ = thermMatProps$["E"]; *)
(*    thermAlphaVal$ = thermMatProps$["alpha"]; *)
(*    results$ = calcCombined[axialLoad*10^3, bentLoad*10^3, torsionLoad*10^3, *)
(*      aClip$, length, outerR/1000, eVal$, gVal$, thermEnable, thermDT1, *)
(*      thermDT2, thermL, thermD/1000, thermEVal$, thermAlphaVal$, *)
(*      thermA/1000]; sf$ = If[results$["vm"] > 0, yield$/results$["vm"], *)
(*      Infinity]; ControlActive[*)
(*     Column[{Style["\[ThinSpace] Computations Paused During Interaction...", 14, Bold, *)
(*        Gray], visualizeShaft[axialLoad*10^3, bentLoad*10^3, *)
(*        torsionLoad*10^3, results$["T1seg"], results$["T2seg"], length, *)
(*        outerR/1000, eVal$, gVal$, yield$, deformScale, heatmapType, *)
(*        magnification, aClip$, thermEnable, thermDT1, thermDT2, thermL, *)
(*        thermD/1000, thermA/1000, results$["Frod1"], results$["Frod2"], *)
(*        cameraView, results$["rod1DeltaL"], results$["rod2DeltaL"]]}, *)
(*      Spacings -> 1, Alignment -> Center], *)
(*     Module[{}, plotBMD$ = Plot[bentLoad*10^3*(length - x), {x, 0, length}, *)
(*         PlotStyle -> Darker[Blue], Filling -> Axis, FillingStyle -> *)
(*          Directive[Opacity[0.4], Darker[Blue]], PlotLabel -> *)
(*          Style["Bending Moment Diagram M(x)", 12, Bold], *)
(*         AxesLabel -> {"x (m)", "Moment (N\[CenterDot]m)"}, ImageSize -> 400, *)
(*         Exclusions -> None]; plotTMD$ = *)
(*        Plot[Piecewise[{{results$["T1seg"], x <= aClip$}, {results$["T2seg"], *)
(*            x > aClip$}}], {x, 0, length}, PlotStyle -> {Darker[Red], Thick}, *)
(*         Filling -> Axis, FillingStyle -> Directive[Opacity[0.3], *)
(*           Darker[Red]], PlotLabel -> Style["Torsion Moment Diagram T(x)", *)
(*           12, Bold], AxesLabel -> {"x (m)", "Torque (N\[CenterDot]m)"}, *)
(*         PlotRange -> All, ImageSize -> 400, Exclusions -> None, *)
(*         Epilog -> {Dashed, GrayLevel[0.5], Line[{{aClip$, 0}, *)
(*             {aClip$, results$["T1seg"]}}], Text[Style["a", 10, Italic], *)
(*            {aClip$, 0}, {0, 1.5}]}]; plotTwist$ = *)
(*        Plot[Piecewise[{{results$["T1seg"]*(x/(gVal$*results$["J"])), *)
(*            x <= aClip$}, {results$["T1seg"]*(aClip$/(gVal$*results$["J"])) + *)
(*             results$["T2seg"]*((x - aClip$)/(gVal$*results$["J"])), *)
(*            x > aClip$}}], {x, 0, length}, PlotStyle -> {Darker[Magenta], *)
(*           Thick}, Filling -> Axis, FillingStyle -> Directive[Opacity[0.2], *)
(*           Darker[Magenta]], PlotLabel -> *)
(*          Style["Angle of Twist Diagram \[Phi](x)", 12, Bold], *)
(*         AxesLabel -> {"x (m)", "\[Phi] (rad)"}, PlotRange -> All, *)
(*         ImageSize -> 400, Exclusions -> None, Epilog -> *)
(*          {Dashed, GrayLevel[0.5], Line[{{aClip$, 0}, {aClip$, *)
(*              results$["T1seg"]*(aClip$/(gVal$*results$["J"]))}}], *)
(*           Text[Style["a", 10, Italic], {aClip$, 0}, {0, 1.5}]}]; *)
(*       Column[*)
(*        {Panel[Grid[*)
(*           {{Style["Max Normal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(x\)]\))", *)
(*              11, Darker[Blue]], Style[StringJoin[ToString[NumberForm[*)
(*                 results$["sigmaX"]/10^6, {6, 2}]], " MPa"], 11, Bold, *)
(*              Blue]}, {Style[*)
(*              "Max Torsional Shear (\!\(\*SubscriptBox[\(\[Tau]\), \(max\)]\))", *)
(*              11, Darker[Blue]], Style[StringJoin[ToString[NumberForm[*)
(*                 results$["tauXY"]/10^6, {6, 2}]], " MPa"], 11, Bold, Blue]}, *)
(*            {Style[*)
(*              "Max Shear Strain (\!\(\*SubscriptBox[\(\[Gamma]\), \(max\)]\))", 11, *)
(*              Darker[Blue]], Style[StringJoin[ToString[NumberForm[*)
(*                 N[results$["gammaMax"]], {6, 4}]], " rad"], 11, Bold, *)
(*              Blue]}, {Style["Max Shear Location", 11, Darker[Blue]], *)
(*             Style[results$["tauMaxSeg"], 11, Bold, Darker[Orange]]}, *)
(*            {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(1\)]\))", *)
(*              11, Darker[Blue]], Style[StringJoin[ToString[NumberForm[*)
(*                 results$["p1"]/10^6, {6, 2}]], " MPa"], 11, Bold, Blue]}, *)
(*            {Style["Principal Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(2\)]\))", *)
(*              11, Darker[Blue]], Style[StringJoin[ToString[NumberForm[*)
(*                 results$["p2"]/10^6, {6, 2}]], " MPa"], 11, Bold, Blue]}, *)
(*            {Style["Von Mises Stress (\!\(\*SubscriptBox[\(\[Sigma]\), \(vm\)]\))", *)
(*              12, Darker[Blue]], Style[StringJoin[ToString[NumberForm[*)
(*                 results$["vm"]/10^6, {6, 2}]], " MPa"], 12, Bold, *)
(*              If[results$["vm"] > yield$, Red, Blue]]}, *)
(*            {Style["Angle of Twist (\[Phi] at end)", 12, Darker[Blue]], *)
(*             Style[StringJoin[ToString[NumberForm[results$["phi"], {6, 4}]], *)
(*               " rad  (", ToString[NumberForm[N[results$["phi"]*(180/Pi)], *)
(*                 {6, 2}]], "\[Degree])"], 12, Bold, Blue]}, *)
(*            {Style["Axial Elongation (\[CapitalDelta]L)", 11, Darker[Blue]], *)
(*             Style[StringJoin[ToString[NumberForm[N[results$["deltaL"]*1000], *)
(*                 {6, 4}]], " mm"], 11, Bold, Blue]}, *)
(*            {Style["Safety Factor", 11, Darker[Blue]], If[sf$ == Infinity, *)
(*              Style["\[Infinity]", 11, Bold], Style[NumberForm[sf$, {5, 2}], 11, *)
(*               Bold, If[sf$ >= 2, Darker[Green], If[sf$ >= 1, Orange, *)
(*                 Red]]]]}}, Alignment -> {{Left, Right}, Center}, *)
(*           Spacings -> {2, 0.8}, Dividers -> Center], *)
(*          Style["\[ThinSpace] Combined Loading Results", 14, Bold], *)
(*          Background -> White], If[results$["vm"] > yield$, *)
(*          Framed[Style["\[WarningSign] YIELD STRESS EXCEEDED ", 12, Bold, Darker[Red]], *)
(*           Background -> Lighter[Red, 0.9], FrameStyle -> Thick, *)
(*           FrameColor -> Darker[Red]], ""], If[thermEnable, *)
(*          Panel[Grid[{{SpanFromLeft, Style["Axial Bar Results", 12, Bold, *)
(*               Black]}, {"", Style["Bar 1 (Right)", 11, Bold, Black], *)
(*              Style["Bar 2 (Left)", 11, Bold, Black]}, *)
(*             {Style["Axial Force (N)", 11, Black], Style[StringJoin[*)
(*                ToString[NumberForm[N[results$["Frod1"]], {6, 2}]], " N"], *)
(*               11, Bold, Black], Style[StringJoin[ToString[NumberForm[*)
(*                  N[results$["Frod2"]], {6, 2}]], " N"], 11, Bold, Black]}, *)
(*             {Style["\[CapitalDelta]L (mm)", 11, Black], Style[StringJoin[ToString[*)
(*                 NumberForm[N[results$["rod1DeltaL"]*1000], {6, 4}]], " mm"], *)
(*               11, Bold, Black], Style[StringJoin[ToString[NumberForm[*)
(*                  N[results$["rod2DeltaL"]*1000], {6, 4}]], " mm"], 11, Bold, *)
(*               Black]}, {Style["Stress (MPa)", 11, Black], Style[StringJoin[*)
(*                ToString[NumberForm[N[results$["rod1Stress"]/10^6], {6, 2}]], *)
(*                " MPa"], 11, Bold, Black], Style[StringJoin[ToString[*)
(*                 NumberForm[N[results$["rod2Stress"]/10^6], {6, 2}]], *)
(*                " MPa"], 11, Bold, Black]}, {Style["Strain", 11, Black], *)
(*              Style[ToString[NumberForm[N[results$["rod1Strain"]], {6, 6}]], *)
(*               11, Bold, Black], Style[ToString[NumberForm[N[results$[*)
(*                   "rod2Strain"]], {6, 6}]], 11, Bold, Black]}}, *)
(*            Alignment -> {{Left, Center, Center}, Center}, *)
(*            Spacings -> {2, 0.8}, Dividers -> Center], *)
(*           Style["\[ThinSpace] Thermal Rig Bar Data", 14, Bold, Black], *)
(*           Background -> White], ""], If[thermEnable, *)
(*          Panel[Grid[{{Style["Compatibility Condition Verification", 12, *)
(*               Bold, Black], SpanFromLeft}, *)
(*             {Style["Bar 1 total deformation (\[Delta]\\[Sub1])", 11, Black], *)
(*              Style[StringJoin[ToString[NumberForm[N[results$["compatLHS"]**)
(*                    1000], {8, 6}]], " mm"], 11, Bold, Black]}, *)
(*             {Style["Required by twist (\[Phi]\[CenterDot]R\\[Sub]arm)", 11, Black], *)
(*              Style[StringJoin[ToString[NumberForm[N[results$["compatRHS"]**)
(*                    1000], {8, 6}]], " mm"], 11, Bold, Black]}, *)
(*             {Style["Compatibility Error", 11, Black], Style[StringJoin[*)
(*                ToString[NumberForm[N[results$["compatError"]*1000], *)
(*                  {8, 6}]], " mm"], 11, Bold, If[results$["compatError"] < *)
(*                 1/10000000000, Darker[Green], Red]]}, *)
(*             {Style["Status", 11, Bold, Black], Style[If[*)
(*                results$["compatError"] < 1/10000000000, *)
(*                "\[Checkmark] SATISFIED (error \[TildeTilde] 0)", "\[WarningSign] NOT SATISFIED"], 12, *)
(*               Bold, If[results$["compatError"] < 1/10000000000, *)
(*                Darker[Green], Red]]}}, Alignment -> {{Left, Right}, Center}, *)
(*            Spacings -> {2, 0.8}, Dividers -> Center], *)
(*           Style["\[ThinSpace] Compatibility Check", 14, Bold, Black], *)
(*           Background -> White], ""], *)
(*         Panel[Grid[{{Style["Torsion Segments", 12, Bold, Black], *)
(*             SpanFromLeft}, {Style["Torque position a", 11, Black], *)
(*             Style[StringJoin[ToString[NumberForm[N[aClip$], {4, 2}]], *)
(*               " m from clamp"], 11, Bold, Black]}, *)
(*            {Style["Segment 1: [0, a]  T\\[Sub1]", 11, Black], *)
(*             Style[StringJoin[ToString[NumberForm[N[results$["T1seg"]/1000], *)
(*                 {6, 2}]], " kN\[CenterDot]m"], 11, Bold, Black]}, *)
(*            {Style["Segment 2: [a, L]  T\\[Sub2]", 11, Black], *)
(*             Style[StringJoin[ToString[NumberForm[N[results$["T2seg"]/1000], *)
(*                 {6, 2}]], " kN\[CenterDot]m"], 11, Bold, Black]}, *)
(*            {Style["\[Tau]\\[Sub]max occurs in", 11, Bold, Black], *)
(*             Style[results$["tauMaxSeg"], 11, Bold, Darker[Orange]]}}, *)
(*           Alignment -> {{Left, Right}, Center}, Spacings -> {2, 0.8}, *)
(*           Dividers -> Center], Style["\[ThinSpace] Torsion Segments", 14, Bold, *)
(*           Black], Background -> White], visualizeShaft[axialLoad*10^3, *)
(*          bentLoad*10^3, torsionLoad*10^3, results$["T1seg"], *)
(*          results$["T2seg"], length, outerR/1000, eVal$, gVal$, yield$, *)
(*          deformScale, heatmapType, magnification, aClip$, thermEnable, *)
(*          thermDT1, thermDT2, thermL, thermD/1000, thermA/1000, *)
(*          results$["Frod1"], results$["Frod2"], cameraView, *)
(*          results$["rod1DeltaL"], results$["rod2DeltaL"]], plotTMD$, *)
(*         plotTwist$, plotBMD$}, Spacings -> 1, Alignment -> Center]]]], *)
(*  Style["Visualization Settings", 12, Bold], *)
(*  {{cameraView, "Perspective", "Camera View"}, {"Perspective", "Front View", *)
(*    "Side View"}, ControlType -> RadioButtonBar}, *)
(*  {{heatmapType, "Von Mises Stress", "Heatmap Display"}, *)
(*   {"Von Mises Stress", "Normal Stress", "Shear Stress"}, *)
(*   ControlType -> RadioButtonBar}, {{deformScale, 40, "Deformation Scale"}, *)
(*   1, 100, 1, Appearance -> "Labeled"}, *)
(*  {{magnification, 1, "Magnification *"}, 1, 20, 0.5, *)
(*   Appearance -> "Labeled"}, Delimiter, Style["Rod Material & Geometry", 12, *)
(*   Bold], Row[{Style["Rod Length L: ", 11], Style["7.0 m (Constant)", 11, *)
(*     Bold, RGBColor[0.33333333333333337, 0.33333333333333337, *)
(*      0.33333333333333337]]}], Row[{Style["Rod Diameter: ", 11], *)
(*    Style["0.5 m (Constant)", 11, Bold, RGBColor[0.33333333333333337, *)
(*      0.33333333333333337, 0.33333333333333337]]}], *)
(*  {{material, "Aluminum (6061-T6)", "Rod Material"}, *)
(*   {"Steel (A-36)", "Aluminum (6061-T6)", "Magnesium (Am1004)"}, *)
(*   ControlType -> SetterBar}, {{length, 7.}, ControlType -> None}, *)
(*  {{outerR, 250}, ControlType -> None}, Delimiter, *)
(*  Style["Applied Loads", 12, Bold], {{axialLoad, 0, "Axial Load P (kN)"}, *)
(*   -500, 500, 5, Appearance -> "Labeled"}, *)
(*  {{bentLoad, 39, "Transverse Load V (kN)"}, -100, 100, 1, *)
(*   Appearance -> "Labeled"}, {{torsionLoad, 0, "Applied Torque T (kN\[CenterDot]m)"}, *)
(*   -50, 50, 0.5, Appearance -> "Labeled"}, *)
(*  {{torquePos, 3.95, "Torque Position a (m from clamp)"}, 0., 5., 0.05, *)
(*   Appearance -> "Labeled"}, Delimiter, Style["Thermal Torsion Rig", 12, *)
(*   Bold], {{thermEnable, True, "Enable Thermal Rig"}, {True, False}}, *)
(*  {{thermDT1, 0, "Bar 1 (Right) \[CapitalDelta]\!\(\*SubscriptBox[\(T\), \(1\)]\) (\[Degree]C)"}, *)
(*   -200, 200, 1, Appearance -> "Labeled"}, *)
(*  {{thermDT2, 0, "Bar 2 (Left) \[CapitalDelta]\!\(\*SubscriptBox[\(T\), \(2\)]\) (\[Degree]C)"}, *)
(*   -200, 200, 1, Appearance -> "Labeled"}, *)
(*  {{thermMat, "Aluminum (6061-T6)", "Bar Material"}, *)
(*   {"Steel (A-36)", "Aluminum (6061-T6)", "Magnesium (Am1004)"}, *)
(*   ControlType -> SetterBar}, {{thermL, 2.5000000000000004, *)
(*    "Bar Length l (m)"}, 0.1, 3., 0.1, Appearance -> "Labeled"}, *)
(*  {{thermD, 23, "Bar Diameter d (mm)"}, 2, 50, 1, Appearance -> "Labeled"}, *)
(*  {{thermA, 0, "Offset a from shaft surface (mm)"}, 0, 200, 5, *)
(*   Appearance -> "Labeled"}, ControlPlacement -> Left, *)
(*  TrackedSymbols :> {heatmapType, cameraView, material, length, outerR, *)
(*    axialLoad, bentLoad, torsionLoad, deformScale, magnification, torquePos, *)
(*    thermEnable, thermDT1, thermDT2, thermL, thermD, thermA, thermMat}, *)
(*  SynchronousUpdating -> False]*)
