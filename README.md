# MechSim: Mechanics of Materials Simulator

**MechSim** is an interactive engineering tool designed to visualize and calculate core concepts in Mechanics of Materials. It provides real-time analysis for structural elements like beams, columns, and trusses, as well as stress transformation and material properties.

## 🤖 For AI Coding Assistants

> **This project has two parallel implementations. Use the correct language for the file you are editing:**
>
> | File Type | Language | Run With |
> |-----------|----------|----------|
> | `.js`, `.html`, `.css` | **JavaScript** (ES Modules + THREE.js) | Web browser (`index.html`) |
> | `.wl` | **Wolfram Language** (Mathematica) | Mathematica / Wolfram Cloud |
>
> - **JavaScript files** power the browser-based 3D simulator.
> - **Wolfram Language files** (`MechSim*.wl`) provide the same engineering analysis as interactive `Manipulate[]` panels for Mathematica.
> - When adding new features, implement in **both** languages if possible.

## 🔧 Two Ways to Run

### Option A: Web Browser (JavaScript)
```bash
git clone https://github.com/bibitybaqityboo/Wolfram-Alpha.git
cd Wolfram-Alpha
# Open index.html in any modern web browser, or use a local server:
python -m http.server
```

### Option B: Mathematica (Wolfram Language)
1. Open any `MechSim*.wl` file in **Mathematica** (or paste into [Wolfram Cloud](https://www.wolframcloud.com/)).
2. Select All → Evaluate. Each file exposes a function like `MechSimBeam[]`, `MechSimMohr[]`, etc.
3. Call the function to launch the interactive `Manipulate[]` panel.

| File | Module | Function |
|------|--------|----------|
| `MechSimBeam.wl` | Beam Analysis | `MechSimBeam[]` |
| `MechSimMohr.wl` | Mohr's Circle | `MechSimMohr[]` |
| `MechSimTorsion.wl` | Torsion | `MechSimTorsion[]` |
| `MechSimColumn.wl` | Column Buckling | `MechSimColumn[]` |
| `MechSimPressure.wl` | Pressure Vessels | `MechSimPressure[]` |
| `MechSimTruss.wl` | Truss Analysis | `MechSimTruss[]` |
| `MechSimMaterial.wl` | Material Testing | `MechSimMaterial[]` |

---

## 🌟 Key Features

### 1. 📐 Beam Analysis
Visualize bending, shear, and stress distribution in real-time.
*   **Support Types:** Simply Supported, Cantilever, Fixed-Fixed, Overhanging.
*   **Loading:** Point loads, distributed loads, and moments.
*   **Outputs:** Shear Force Diagrams (SFD), Bending Moment Diagrams (BMD), Deflection curves, and Stress Heatmaps.
*   **Theory:** Supports both Euler-Bernoulli (thin) and Timoshenko (thick) beam theories.

### 2. 🏛 Column Buckling
Analyze stability and critical loads for columns.
*   **End Conditions:** Pinned-Pinned, Fixed-Free, Fixed-Pinned, Fixed-Fixed.
*   **Calculations:** Computes Critical Load ($P_{cr}$) using Euler's Formula and Johnson's Parabola for intermediate columns.
*   **Visuals:** Real-time buckling mode shape visualization.

### 3. 🔄 Torsion
Simulate twisting of circular shafts.
*   **Geometry:** Solid or hollow shafts with variable radii.
*   **Analysis:** Calculates Shear Stress ($\tau$), Angle of Twist ($\phi$), and safety factors.
*   **Power:** Relate torque and RPM to power transmission.

### 4. ⊚ Mohr's Circle
Interactive tool for 2D stress transformation.
*   **Inputs:** Normal stresses ($\sigma_x, \sigma_y$) and shear stress ($\tau_{xy}$).
*   **Outputs:** Principal stresses ($\sigma_1, \sigma_2$), maximum shear stress ($\tau_{max}$), and principal orientation ($\theta_p$).
*   **Failure Theories:** Calculates Von Mises and Tresca criteria.

### 5. 🛢 Pressure Vessels
Analyze stresses in thin and thick-walled vessels.
*   **Shapes:** Cylindrical and Spherical vessels.
*   **Stresses:** Computes Hoop, Longitudinal, and Radial stresses.
*   **Safety:** Real-time safety factor calculation based on material yield strength.

### 6. 🔺 Truss Analysis
Design and solve 2D truss structures.
*   **Method:** Direct Stiffness Method for exact solution.
*   **Builder:** Drag-and-drop nodes, members, and supports (Pin/Roller).
*   **Templates:** One-click generation of Pratt, Warren, Howe, and K-Trusses.
*   **Results:** Visualizes member tension/compression (color-coded) and node displacement.

### 7. 🧪 Material Testing
Virtual tensile test simulation.
*   **Materials:** Steel, Aluminum, Copper, Titanium, Cast Iron, and Concrete.
*   **Simulation:** Animates the stress-strain curve, showing elastic region, yielding, strain hardening, and fracture.
*   **Comparison:** Side-by-side comparison of different materials.




## 🤝 Contributing

We welcome contributions! Please follow our **Git Workflow**:

1.  **Main Branch is Protected:** Never push directly to `main`.
2.  **Use Development:** Always base your work on the `development` branch.
    ```bash
    git checkout development
    git pull origin development
    git checkout -b feature/my-new-feature
    ```
3.  **Pull Requests:** Submit a PR to merge your changes back into `development`.

## 📄 License
This project is an Honors Contract for MAE 213.
