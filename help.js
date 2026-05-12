// ═══════════════════════════════════════════════════════════════
// help.js — Help System with per-module theory, formulas, tips
// ═══════════════════════════════════════════════════════════════

const helpContent = {
    combined: {
        title: 'Combined Loading',
        subtitle: 'Axial, Bending & Torsional Stresses',
        body: `
            <h3>Overview</h3>
            <p>Combined loading analysis evaluates the superposition of stresses when a structural member is subjected to simultaneous axial, bending, and torsional loads.</p>

            <h3>Normal Stress (σx)</h3>
            <p>The total normal stress is the algebraic sum of axial and bending stresses.</p>
            <div class="formula">σx = (P / A) ± (M·y / I)</div>
            <p>Where P is axial load, A is cross-sectional area, M is bending moment, y is the distance from the neutral axis, and I is the moment of inertia.</p>

            <h3>Shear Stress (τxy)</h3>
            <p>The shear stress is primarily driven by torsion for solid/hollow round shafts.</p>
            <div class="formula">τxy = T·r / J</div>
            <p>Where T is torque, r is the radial distance, and J is the polar moment of inertia.</p>

            <h3>Principal Stresses</h3>
            <p>Using Mohr's Circle equations for a generic 2D stress element on the surface:</p>
            <div class="formula">σ₁,₂ = (σx / 2) ± √[(σx / 2)² + τxy²]</div>

            <h3>Von Mises Failure Criterion</h3>
            <p>The Von Mises stress indicates yielding for ductile materials under multiaxial loading.</p>
            <div class="formula">σ_vm = √[σ₁² − σ₁σ₂ + σ₂²]</div>
            <p>Yielding is predicted when σ_vm ≥ Yield Strength of the material.</p>

            <div class="tip"><span class="tip-icon">💡</span> The heatmap colors the shaft based on the ratio of local Von Mises stress to the material's yield strength. Red indicates yielding.</div>
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
