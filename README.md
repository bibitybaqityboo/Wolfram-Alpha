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

### 1. 🔄 Combined Loading Simulator
Visualize the compounded effects of simultaneous axial, bending, and torsional loads in real-time on a 3D structural member.
*   **Loads:** Customizable Axial Load, Transverse (Bending) Load, and Torque.
*   **Geometry:** Configurable shaft length and inner/outer radii (hollow or solid).
*   **Analysis:** Calculates Principal Stresses ($\sigma_1, \sigma_2$), Max Normal Stress ($\sigma_x$), Max Shear Stress ($\tau_{xy}$), and Von Mises Stress ($\sigma_{vm}$).
*   **Safety:** Real-time safety factor calculation and yielding warnings based on the selected material.
*   **Visuals:** Dynamic 3D deformation reflecting axial elongation, bending deflection, and torsional twist, overlaid with a Von Mises stress heatmap.

> **Note:** Additional standalone analysis modules (Beam, Truss, Pressure Vessels, etc.) are available in the Wolfram Language (`.wl`) implementation.




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
