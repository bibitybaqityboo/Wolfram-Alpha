// ═══════════════════════════════════════════════════════════════
// help.js — Help System with per-module theory, formulas, tips
// ═══════════════════════════════════════════════════════════════

const helpContent = {
    beam: {
        title: 'Beam Analysis',
        subtitle: 'Euler-Bernoulli & Timoshenko Beam Theory',
        body: `
            <h3>Overview</h3>
            <p>Beam analysis determines the deflection, bending stress, and shear stress in a structural beam under various loading conditions. This module supports both Euler-Bernoulli (classical thin beam) and Timoshenko (thick beam with shear deformation) theories.</p>

            <h3>Key Formulas</h3>
            <div class="formula">σ = M·y / I</div>
            <p>Where σ is bending stress, M is bending moment, y is distance from neutral axis, and I is the second moment of area.</p>

            <div class="formula">δ_max = P·L³ / (48·E·I)   (simply supported, center load)</div>

            <div class="formula">I = b·h³ / 12   (rectangular section)</div>

            <h3>Support Types</h3>
            <table>
                <tr><th>Type</th><th>Left End</th><th>Right End</th><th>Reactions</th></tr>
                <tr><td>Simply Supported</td><td>Pin (V, H)</td><td>Roller (V)</td><td>3</td></tr>
                <tr><td>Cantilever</td><td>Fixed (V, H, M)</td><td>Free</td><td>3</td></tr>
                <tr><td>Fixed-Fixed</td><td>Fixed (V, H, M)</td><td>Fixed (V, M)</td><td>6</td></tr>
                <tr><td>Overhanging</td><td>Pin (V, H)</td><td>Roller (V) at 75%</td><td>3</td></tr>
            </table>

            <h3>Timoshenko vs Euler-Bernoulli</h3>
            <p>Timoshenko beam theory accounts for shear deformation and is more accurate for short, thick beams where the span-to-depth ratio is less than ~10. The correction factor κ (shear coefficient) depends on the cross-section shape — for a rectangle, κ = 5/6.</p>

            <div class="tip"><span class="tip-icon">💡</span> Use Timoshenko theory when L/h < 10. For most practical beams (L/h > 20), Euler-Bernoulli is sufficiently accurate.</div>

            <h3>Sign Convention</h3>
            <p>Positive loads act downward. Positive moment causes sagging (concave up). Positive shear acts clockwise on the element.</p>
        `
    },
    mohr: {
        title: "Mohr's Circle",
        subtitle: 'Stress Transformation & Principal Stresses',
        body: `
            <h3>Overview</h3>
            <p>Mohr's Circle is a graphical method for determining principal stresses, maximum shear stress, and stress on any inclined plane from a known stress state. This module supports both 2D and 3D stress states.</p>

            <h3>Key Formulas</h3>
            <div class="formula">σ₁,₂ = (σx + σy)/2 ± √[((σx − σy)/2)² + τxy²]</div>

            <div class="formula">τ_max = (σ₁ − σ₂) / 2</div>

            <div class="formula">θ_p = ½ · arctan(2τxy / (σx − σy))</div>

            <h3>Von Mises Criterion</h3>
            <div class="formula">σ_vm = √[σ₁² − σ₁σ₂ + σ₂²]   (2D)</div>
            <div class="formula">σ_vm = √[½((σ₁−σ₂)² + (σ₂−σ₃)² + (σ₃−σ₁)²)]   (3D)</div>
            <p>Yielding occurs when σ_vm ≥ σ_yield. Von Mises is most appropriate for ductile materials under multiaxial stress.</p>

            <h3>3D Stress State</h3>
            <p>When σz ≠ 0, three Mohr's circles are drawn representing the three principal stress planes. The maximum shear stress is determined by the largest circle.</p>

            <div class="tip"><span class="tip-icon">💡</span> Set σz to see the 3D Mohr's circle — three concentric circles showing all principal plane combinations.</div>
        `
    },
    torsion: {
        title: 'Torsion Analysis',
        subtitle: 'Circular Shaft Under Torque',
        body: `
            <h3>Overview</h3>
            <p>Torsion analysis determines the shear stress and angle of twist in circular shafts subjected to torque. The analysis assumes the shaft is prismatic, circular, and made of a linear elastic material.</p>

            <h3>Key Formulas</h3>
            <div class="formula">τ = T·r / J</div>
            <p>Where τ is shear stress, T is applied torque, r is radial distance, J is polar moment of inertia.</p>

            <div class="formula">φ = T·L / (G·J)</div>
            <p>Where φ is the total angle of twist, L is shaft length, G is shear modulus.</p>

            <div class="formula">J = π·r⁴/2   (solid)     J = π(r₀⁴ − rᵢ⁴)/2   (hollow)</div>

            <h3>Power Transmission</h3>
            <div class="formula">P = T · ω = T · (2π·n/60)</div>
            <p>Where P is power in watts, ω is angular velocity in rad/s, n is shaft speed in RPM.</p>

            <h3>Hollow Shafts</h3>
            <p>Hollow shafts are more weight-efficient because material near the center contributes little to resisting torsion. The ratio rᵢ/r₀ is typically between 0.5 and 0.8 for optimal design.</p>

            <div class="tip"><span class="tip-icon">💡</span> A hollow shaft with rᵢ/r₀ = 0.8 has ~60% of the weight but retains ~95% of the torsional strength of a solid shaft.</div>
        `
    },
    column: {
        title: 'Column Buckling',
        subtitle: "Euler's Formula & Johnson's Parabola",
        body: `
            <h3>Overview</h3>
            <p>Column buckling analysis determines the critical load at which a column will buckle under axial compression. Long columns buckle elastically (Euler), while short columns experience inelastic buckling (Johnson).</p>

            <h3>Euler Buckling (Long Columns)</h3>
            <div class="formula">P_cr = π²·E·I / (K·L)²</div>
            <p>Valid when the slenderness ratio λ > λ_c (transition slenderness).</p>

            <h3>Johnson's Parabola (Short Columns)</h3>
            <div class="formula">P_cr = A [σ_y − (σ_y²/(4π²E)) · (KL/r)²]</div>
            <p>Used when λ ≤ λ_c, where yielding occurs before elastic buckling.</p>

            <div class="formula">λ_c = √(2π²E / σ_y)</div>

            <h3>Effective Length Factors</h3>
            <table>
                <tr><th>End Condition</th><th>K</th><th>Effective Length</th></tr>
                <tr><td>Pinned-Pinned</td><td>1.0</td><td>L</td></tr>
                <tr><td>Fixed-Free</td><td>2.0</td><td>2L</td></tr>
                <tr><td>Fixed-Pinned</td><td>0.7</td><td>0.7L</td></tr>
                <tr><td>Fixed-Fixed</td><td>0.5</td><td>0.5L</td></tr>
            </table>

            <div class="tip"><span class="tip-icon">💡</span> The buckling mode (n) shows higher-order shapes but requires n² times the critical load. In practice, buckling always occurs in the first mode.</div>
        `
    },
    pressure: {
        title: 'Pressure Vessels',
        subtitle: 'Thin & Thick Wall Analysis',
        body: `
            <h3>Overview</h3>
            <p>Pressure vessel analysis determines hoop, longitudinal, and radial stresses in cylinders and spheres under internal/external pressure. Thin-wall theory is used when r/t > 10.</p>

            <h3>Thin-Walled Cylinder</h3>
            <div class="formula">σ_hoop = p·r / t</div>
            <div class="formula">σ_long = p·r / (2t)   (closed ends)</div>

            <h3>Thin-Walled Sphere</h3>
            <div class="formula">σ = p·r / (2t)</div>

            <h3>Thick-Walled (Lamé Equations)</h3>
            <div class="formula">σ_r = A − B/r²     σ_θ = A + B/r²</div>
            <p>Where A and B are determined from boundary conditions at inner and outer radii.</p>

            <h3>End Cap Effects</h3>
            <p>Closed vessels have longitudinal stress from end-cap pressure. Open vessels (like a pipe between two flanges) have σ_long = 0.</p>

            <div class="tip"><span class="tip-icon">💡</span> Hoop stress is always the largest stress in a thin-walled cylinder — twice the longitudinal stress. This is why cylindrical vessels tend to fail along longitudinal seams.</div>
        `
    },
    truss: {
        title: 'Truss Analysis',
        subtitle: 'Direct Stiffness Method',
        body: `
            <h3>Overview</h3>
            <p>Truss analysis uses the Direct Stiffness Method to determine member forces and joint displacements. Members carry only axial forces (tension or compression) with pin connections at joints.</p>

            <h3>Method</h3>
            <p>For each member, the local stiffness matrix is assembled, transformed to global coordinates, and combined into the global stiffness matrix. Solving [K]{d} = {F} gives displacements.</p>

            <div class="formula">[K] = (AE/L) · [c²  cs  -c²  -cs; cs  s²  -cs  -s²; ...]</div>
            <p>Where c = cos(θ), s = sin(θ), θ is the member angle.</p>

            <h3>Templates</h3>
            <table>
                <tr><th>Truss Type</th><th>Web Members</th><th>Best For</th></tr>
                <tr><td>Pratt</td><td>Vertical + diagonal</td><td>Vertical loads</td></tr>
                <tr><td>Warren</td><td>Diagonal only</td><td>Uniform loads</td></tr>
                <tr><td>Howe</td><td>Vertical + diagonal</td><td>Gravity loads</td></tr>
                <tr><td>K Truss</td><td>K-pattern</td><td>Long spans</td></tr>
            </table>

            <h3>Color Coding</h3>
            <p>After analysis, members are colored by force magnitude: 🔵 blue for tension, 🔴 red for compression. Brighter colors indicate higher forces.</p>

            <div class="tip"><span class="tip-icon">💡</span> Use the deformation scale slider to exaggerate displacements and visualize the deformed shape clearly.</div>
        `
    },
    material: {
        title: 'Material Testing',
        subtitle: 'Virtual Tensile Test Machine',
        body: `
            <h3>Overview</h3>
            <p>Simulate a uniaxial tensile test to explore the stress-strain behavior of engineering materials. Watch the specimen deform, neck, and fracture in real time while observing the stress-strain curve.</p>

            <h3>Stress-Strain Regions</h3>
            <table>
                <tr><th>Region</th><th>Behavior</th><th>Key Point</th></tr>
                <tr><td>Elastic</td><td>Linear, reversible</td><td>σ = E·ε</td></tr>
                <tr><td>Yielding</td><td>Onset of plastic deformation</td><td>σ_y</td></tr>
                <tr><td>Strain Hardening</td><td>Increasing stress</td><td>σ_ult</td></tr>
                <tr><td>Necking</td><td>Localized deformation</td><td>Instability point</td></tr>
                <tr><td>Fracture</td><td>Complete failure</td><td>ε_f</td></tr>
            </table>

            <h3>True vs Engineering Stress</h3>
            <div class="formula">σ_true = σ_eng · (1 + ε_eng)</div>
            <div class="formula">ε_true = ln(1 + ε_eng)</div>
            <p>True stress accounts for the reduction in cross-sectional area during deformation, and continues to increase even during necking.</p>

            <h3>Toughness & Resilience</h3>
            <p><strong>Resilience</strong> = area under elastic curve = σ_y²/(2E). <strong>Toughness</strong> = total area under the stress-strain curve to fracture.</p>

            <div class="tip"><span class="tip-icon">💡</span> Compare materials side-by-side to visualize differences in ductility, strength, and stiffness. Toggle True Stress mode to see real material behavior during necking.</div>
        `
    }
};

export function initHelpSystem() {
    const modal = document.getElementById('help-modal');
    const backdrop = document.getElementById('help-modal-backdrop');
    const closeBtn = document.getElementById('help-modal-close');
    const titleEl = document.getElementById('help-modal-title');
    const subtitleEl = document.getElementById('help-modal-subtitle');
    const bodyEl = document.getElementById('help-modal-body');

    function openHelp(moduleId) {
        const info = helpContent[moduleId];
        if (!info) return;
        titleEl.textContent = info.title;
        subtitleEl.textContent = info.subtitle;
        bodyEl.innerHTML = info.body;
        modal.classList.add('visible');
    }

    function closeHelp() {
        modal.classList.remove('visible');
    }

    // Help buttons on panels
    document.querySelectorAll('.help-btn[data-help]').forEach(btn => {
        btn.addEventListener('click', () => openHelp(btn.dataset.help));
    });

    // Close events
    closeBtn.addEventListener('click', closeHelp);
    backdrop.addEventListener('click', closeHelp);
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeHelp();
    });
}
