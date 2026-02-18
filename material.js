// ═══════════════════════════════════════════════════════════════
// material.js — Material Testing Module
// Virtual tensile test machine with stress-strain curve
// True stress/strain toggle & toughness calculation
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, registerModule, TENSILE_MATERIALS, overlayCanvas, overlayCtx, clamp, getCachedMaterial } from './app.js';

const $ = id => document.getElementById(id);
let group;
let specimenMesh, specimenGeom, specimenMat, originalPositions;
let topGrip, bottomGrip;
let running = false;
let currentStrain = 0;
let fractured = false;
let stressHistory = [];
let compareHistory = [];

const SPECIMEN_SEGS_X = 4;
const SPECIMEN_SEGS_Y = 40;

const state = {
    material: 'steel',
    material2: 'aluminum',
    compare: false,
    strainRate: 1,
    trueStress: false,
};

function getMat() { return TENSILE_MATERIALS[state.material]; }

function calcStress(strain, mat) {
    if (!mat) mat = getMat();
    if (strain <= 0) return 0;

    const { E, sigmaY, sigmaUlt, strainUlt, strainFracture, n } = mat;
    const strainYield = sigmaY / E;

    if (strain >= strainFracture) return 0;

    if (strain <= strainYield) {
        // Linear elastic region
        return E * strain;
    } else if (strain <= strainUlt) {
        // Plastic hardening — Hollomon's equation: σ = K · ε_p^n
        // K is the strength coefficient: K = σ_ult / (ε_ult - ε_yield)^n
        const plasticStrain = strain - strainYield;
        const maxPlasticStrain = strainUlt - strainYield;
        const nExp = n || 0.15;
        if (maxPlasticStrain <= 0) return sigmaY;
        const K = (sigmaUlt - sigmaY) / Math.pow(maxPlasticStrain, nExp);
        return sigmaY + K * Math.pow(plasticStrain, nExp);
    } else {
        // Necking region — stress drops parabolically to fracture
        const neckStrain = strain - strainUlt;
        const neckRange = strainFracture - strainUlt;
        if (neckRange <= 0) return 0;
        const t = neckStrain / neckRange;
        return sigmaUlt * (1 - t * t);
    }
}

// True stress = σ_eng * (1 + ε_eng)
// True strain = ln(1 + ε_eng)
// NOTE: These relations are only valid up to necking (UTS point).
// After necking, uniform deformation assumption breaks.
function calcTrueStress(engStrain, mat) {
    if (!mat) mat = getMat();
    const engStress = calcStress(engStrain, mat);
    if (engStrain >= mat.strainFracture) return 0;
    // Cap at UTS strain — beyond necking, true stress formula is invalid
    const cappedStrain = Math.min(engStrain, mat.strainUlt);
    if (engStrain > mat.strainUlt) {
        // After necking, return the peak true stress (at UTS)
        const utsEngStress = calcStress(mat.strainUlt, mat);
        return utsEngStress * (1 + mat.strainUlt);
    }
    return engStress * (1 + cappedStrain);
}

function calcTrueStrain(engStrain) {
    if (engStrain <= 0) return 0;
    return Math.log(1 + engStrain);
}

// Toughness = area under stress-strain curve (trapezoidal integration)
function calcToughness(mat) {
    if (!mat) mat = getMat();
    let area = 0;
    const steps = 500;
    const dStrain = mat.strainFracture / steps;
    for (let i = 0; i < steps; i++) {
        const s1 = calcStress(i * dStrain, mat);
        const s2 = calcStress((i + 1) * dStrain, mat);
        area += (s1 + s2) / 2 * dStrain;
    }
    return area; // MPa (since stress is in MPa and strain is unitless) = MJ/m³
}

// Resilience = area under elastic portion = σ_y² / (2E)
function calcResilience(mat) {
    if (!mat) mat = getMat();
    return (mat.sigmaY * mat.sigmaY) / (2 * mat.E);
}

// ═══════════════════════════════════════════════════════════════
// 3D Specimen & Grips
// ═══════════════════════════════════════════════════════════════

function createSpecimen() {
    if (specimenMesh) {
        group.remove(specimenMesh);
        specimenGeom.dispose();
        specimenMat.dispose();
    }

    specimenGeom = new THREE.CylinderGeometry(0.15, 0.15, 2, 16, SPECIMEN_SEGS_Y, false);
    specimenMat = new THREE.MeshStandardMaterial({
        color: 0x8899aa,
        roughness: 0.35,
        metalness: 0.7,
        vertexColors: true,
    });
    specimenMesh = new THREE.Mesh(specimenGeom, specimenMat);
    specimenMesh.position.set(0, 1.5, 0);
    specimenMesh.castShadow = true;
    group.add(specimenMesh);

    originalPositions = specimenGeom.attributes.position.array.slice();
}

function createGrips() {
    if (topGrip) { group.remove(topGrip); topGrip.geometry.dispose(); topGrip.material.dispose(); }
    if (bottomGrip) { group.remove(bottomGrip); bottomGrip.geometry.dispose(); bottomGrip.material.dispose(); }

    const gripGeo = new THREE.BoxGeometry(0.6, 0.25, 0.6);
    const gripMat = getCachedMaterial(0x444444, { roughness: 0.6, metalness: 0.4 });

    bottomGrip = new THREE.Mesh(gripGeo, gripMat.clone());
    bottomGrip.position.set(0, 0.4, 0);
    bottomGrip.castShadow = true;
    group.add(bottomGrip);

    topGrip = new THREE.Mesh(gripGeo.clone(), gripMat.clone());
    topGrip.position.set(0, 2.6, 0);
    topGrip.castShadow = true;
    group.add(topGrip);

    const colGeo = new THREE.CylinderGeometry(0.04, 0.04, 3.5, 8);
    const colMat = getCachedMaterial(0x333333, { roughness: 0.8, metalness: 0.3 });

    for (const xOff of [-0.4, 0.4]) {
        for (const zOff of [-0.4, 0.4]) {
            const col = new THREE.Mesh(colGeo.clone(), colMat.clone());
            col.position.set(xOff, 1.5, zOff);
            col.castShadow = true;
            group.add(col);
        }
    }

    const baseGeo = new THREE.BoxGeometry(1.2, 0.1, 1.2);
    const baseMat = getCachedMaterial(0x333333, { roughness: 0.7, metalness: 0.3 });
    const base = new THREE.Mesh(baseGeo, baseMat);
    base.position.set(0, -0.05, 0);
    base.castShadow = true;
    group.add(base);

    const topPlate = new THREE.Mesh(baseGeo.clone(), baseMat.clone());
    topPlate.position.set(0, 3.25, 0);
    topPlate.castShadow = true;
    group.add(topPlate);
}

// ═══════════════════════════════════════════════════════════════
// Deformation
// ═══════════════════════════════════════════════════════════════

function deformSpecimen() {
    if (!specimenMesh) return;

    const pos = specimenGeom.attributes.position;
    const mat = getMat();
    const stress = calcStress(currentStrain, mat);
    const isFractured = currentStrain >= mat.strainFracture;
    const isNecking = currentStrain > mat.strainUlt;
    const colors = new Float32Array(pos.count * 3);

    for (let i = 0; i < pos.count; i++) {
        const ox = originalPositions[i * 3];
        const oy = originalPositions[i * 3 + 1];
        const oz = originalPositions[i * 3 + 2];

        const yNorm = (oy + 1) / 2;

        let newY = oy + oy * currentStrain;

        let radiusScale = 1;
        if (isNecking && !isFractured) {
            const neckProgress = (currentStrain - mat.strainUlt) / (mat.strainFracture - mat.strainUlt);
            const distFromCenter = Math.abs(yNorm - 0.5) * 2;
            const neckFactor = 1 - neckProgress * 0.6 * Math.exp(-distFromCenter * distFromCenter * 4);
            radiusScale = neckFactor;
        }

        const poissonRatio = 0.3;
        const lateralStrain = -poissonRatio * Math.min(currentStrain, mat.sigmaY / mat.E);
        radiusScale *= (1 + lateralStrain);

        if (isFractured) {
            const gap = (currentStrain - mat.strainFracture) * 5;
            if (yNorm > 0.5) newY += gap;
            else newY -= gap;
            radiusScale *= 0.8;
        }

        const r = Math.sqrt(ox * ox + oz * oz);
        const theta = Math.atan2(oz, ox);
        const newR = r * radiusScale;

        pos.array[i * 3] = newR * Math.cos(theta);
        pos.array[i * 3 + 1] = newY;
        pos.array[i * 3 + 2] = newR * Math.sin(theta);

        const maxStress = mat.sigmaUlt;
        const t = clamp(Math.abs(stress) / maxStress, 0, 1);
        let cr, cg, cb;
        if (t < 0.33) {
            cr = 0; cg = t / 0.33; cb = 1 - t / 0.33;
        } else if (t < 0.66) {
            const tt = (t - 0.33) / 0.33;
            cr = tt; cg = 1; cb = 0;
        } else {
            const tt = (t - 0.66) / 0.34;
            cr = 1; cg = 1 - tt; cb = 0;
        }
        colors[i * 3] = cr;
        colors[i * 3 + 1] = cg;
        colors[i * 3 + 2] = cb;
    }

    pos.needsUpdate = true;
    specimenGeom.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    specimenGeom.computeVertexNormals();

    if (topGrip) {
        topGrip.position.y = 2.6 + currentStrain * 2;
    }
}

// ═══════════════════════════════════════════════════════════════
// Stress-Strain Curve (2D Overlay)
// ═══════════════════════════════════════════════════════════════

function drawStressStrainCurve() {
    const canvas = overlayCanvas;
    const ctx = overlayCtx;
    const w = canvas.width / window.devicePixelRatio;
    const h = canvas.height / window.devicePixelRatio;

    ctx.clearRect(0, 0, w, h);

    const mat = getMat();
    const mat2 = state.compare ? TENSILE_MATERIALS[state.material2] : null;
    const useTrue = state.trueStress;

    // Graph layout
    const margin = { top: 35, right: 20, bottom: 40, left: 55 };
    const gw = w - margin.left - margin.right;
    const gh = h - margin.top - margin.bottom;

    // Scale
    let maxStrainVal = Math.max(mat.strainFracture * 1.2, mat2 ? mat2.strainFracture * 1.2 : 0, 0.01);
    let maxStressVal = Math.max(mat.sigmaUlt * 1.3, mat2 ? mat2.sigmaUlt * 1.3 : 0, 100);
    if (useTrue) {
        maxStressVal *= 1.4; // true stress is higher
        maxStrainVal = calcTrueStrain(maxStrainVal);
    }

    function toX(strain) { return margin.left + (strain / maxStrainVal) * gw; }
    function toY(stress) { return margin.top + gh - (stress / maxStressVal) * gh; }

    // Grid
    ctx.strokeStyle = 'rgba(255,255,255,0.05)';
    ctx.lineWidth = 0.5;
    for (let i = 0; i <= 5; i++) {
        const x = margin.left + (i / 5) * gw;
        ctx.beginPath(); ctx.moveTo(x, margin.top); ctx.lineTo(x, margin.top + gh); ctx.stroke();
        const y = margin.top + (i / 5) * gh;
        ctx.beginPath(); ctx.moveTo(margin.left, y); ctx.lineTo(margin.left + gw, y); ctx.stroke();
    }

    // Axes
    ctx.strokeStyle = 'rgba(255,255,255,0.2)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(margin.left, margin.top);
    ctx.lineTo(margin.left, margin.top + gh);
    ctx.lineTo(margin.left + gw, margin.top + gh);
    ctx.stroke();

    // Labels
    ctx.fillStyle = 'rgba(255,255,255,0.5)';
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(useTrue ? 'True Strain (ε_t)' : 'Strain (ε)', margin.left + gw / 2, h - 8);

    ctx.save();
    ctx.translate(12, margin.top + gh / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText(useTrue ? 'True Stress σ_t (MPa)' : 'Stress σ (MPa)', 0, 0);
    ctx.restore();

    // Axis tick labels
    ctx.font = '9px Inter, sans-serif';
    ctx.textAlign = 'center';
    for (let i = 0; i <= 5; i++) {
        const strainVal = (i / 5) * maxStrainVal;
        ctx.fillText((strainVal * 100).toFixed(1) + '%', toX(strainVal), margin.top + gh + 15);
    }
    ctx.textAlign = 'right';
    for (let i = 0; i <= 5; i++) {
        const stressVal = (i / 5) * maxStressVal;
        ctx.fillText(stressVal.toFixed(0), margin.left - 8, toY(stressVal) + 3);
    }

    // Draw full curve (theoretical)
    function drawCurve(material, color, alpha = 0.3) {
        ctx.strokeStyle = color;
        ctx.lineWidth = 1;
        ctx.globalAlpha = alpha;
        ctx.beginPath();
        const steps = 200;
        for (let i = 0; i <= steps; i++) {
            const engS = (i / steps) * material.strainFracture;
            let strain, stress;
            if (useTrue) {
                strain = calcTrueStrain(engS);
                stress = calcTrueStress(engS, material);
            } else {
                strain = engS;
                stress = calcStress(engS, material);
            }
            if (i === 0) ctx.moveTo(toX(strain), toY(stress));
            else ctx.lineTo(toX(strain), toY(stress));
        }
        ctx.stroke();
        ctx.globalAlpha = 1;
    }

    drawCurve(mat, mat.color, 0.25);
    if (mat2) drawCurve(mat2, mat2.color, 0.25);

    // Draw animated progress curve
    function drawProgress(history, color) {
        if (history.length < 2) return;
        ctx.strokeStyle = color;
        ctx.lineWidth = 2.5;
        ctx.shadowColor = color;
        ctx.shadowBlur = 8;
        ctx.beginPath();
        for (let i = 0; i < history.length; i++) {
            let { strain, stress } = history[i];
            if (useTrue) {
                stress = stress * (1 + strain);
                strain = calcTrueStrain(strain);
            }
            if (i === 0) ctx.moveTo(toX(strain), toY(stress));
            else ctx.lineTo(toX(strain), toY(stress));
        }
        ctx.stroke();
        ctx.shadowBlur = 0;

        if (history.length > 0) {
            const last = history[history.length - 1];
            let ls = last.strain, lst = last.stress;
            if (useTrue) {
                lst = lst * (1 + ls);
                ls = calcTrueStrain(ls);
            }
            ctx.fillStyle = color;
            ctx.beginPath();
            ctx.arc(toX(ls), toY(lst), 4, 0, 2 * Math.PI);
            ctx.fill();
        }
    }

    drawProgress(stressHistory, mat.color);
    if (mat2 && compareHistory.length) drawProgress(compareHistory, mat2.color);

    // ── Resilience Area Shading (elastic region) ──
    const strainYield = mat.sigmaY / mat.E;
    const strainYieldPlot = useTrue ? calcTrueStrain(strainYield) : strainYield;
    const yieldStress = useTrue ? mat.sigmaY * (1 + strainYield) : mat.sigmaY;

    ctx.globalAlpha = 0.08;
    ctx.fillStyle = '#3fb950';
    ctx.beginPath();
    ctx.moveTo(toX(0), toY(0));
    const elasticSteps = 30;
    for (let i = 0; i <= elasticSteps; i++) {
        const es = (i / elasticSteps) * strainYield;
        const s = useTrue ? calcTrueStress(es, mat) : calcStress(es, mat);
        const plotS = useTrue ? calcTrueStrain(es) : es;
        ctx.lineTo(toX(plotS), toY(s));
    }
    ctx.lineTo(toX(strainYieldPlot), toY(0));
    ctx.closePath();
    ctx.fill();
    ctx.globalAlpha = 1;

    // ── 0.2% Offset Yield Line ──
    const offsetStrain = 0.002; // 0.2%
    ctx.setLineDash([4, 4]);
    ctx.strokeStyle = 'rgba(63, 185, 80, 0.5)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    const offsetEnd = strainYield + offsetStrain * 2;
    const offsetEndPlot = useTrue ? calcTrueStrain(offsetEnd) : offsetEnd;
    ctx.moveTo(toX(useTrue ? calcTrueStrain(offsetStrain) : offsetStrain), toY(0));
    ctx.lineTo(toX(offsetEndPlot), toY(mat.E * (offsetEnd - offsetStrain)));
    ctx.stroke();
    ctx.setLineDash([]);

    // ── Yield stress horizontal line ──
    ctx.setLineDash([3, 3]);
    ctx.strokeStyle = 'rgba(255,255,255,0.12)';
    ctx.lineWidth = 0.5;
    const yieldY = toY(yieldStress);
    ctx.beginPath(); ctx.moveTo(margin.left, yieldY); ctx.lineTo(margin.left + gw, yieldY); ctx.stroke();
    ctx.setLineDash([]);

    // ── UTS horizontal line ──
    const utsStress = useTrue ? mat.sigmaUlt * (1 + mat.strainUlt) : mat.sigmaUlt;
    ctx.setLineDash([2, 4]);
    ctx.strokeStyle = 'rgba(248, 81, 73, 0.2)';
    ctx.beginPath(); ctx.moveTo(margin.left, toY(utsStress)); ctx.lineTo(margin.left + gw, toY(utsStress)); ctx.stroke();
    ctx.setLineDash([]);

    // ── Region Labels ──
    ctx.font = '8px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.globalAlpha = 0.45;

    // Elastic region
    const elasticMid = strainYieldPlot / 2;
    if (toX(elasticMid) > margin.left + 5) {
        ctx.fillStyle = '#3fb950';
        ctx.fillText('Elastic', toX(elasticMid), margin.top + gh - 8);
    }

    // Plastic hardening region
    const hardenMid = useTrue ? calcTrueStrain((strainYield + mat.strainUlt) / 2) : (strainYield + mat.strainUlt) / 2;
    ctx.fillStyle = '#58a6ff';
    ctx.fillText('Hardening', toX(hardenMid), margin.top + gh - 8);

    // Necking region
    const neckMid = useTrue ? calcTrueStrain((mat.strainUlt + mat.strainFracture) / 2) : (mat.strainUlt + mat.strainFracture) / 2;
    ctx.fillStyle = '#d29922';
    ctx.fillText('Necking', toX(neckMid), margin.top + gh - 8);

    ctx.globalAlpha = 1;

    // ── Stress annotations ──
    ctx.fillStyle = 'rgba(255,255,255,0.35)';
    ctx.textAlign = 'left';
    ctx.font = '9px Inter, sans-serif';
    ctx.fillText('σ_y = ' + mat.sigmaY + ' MPa', margin.left + gw - 90, yieldY - 4);
    ctx.fillStyle = 'rgba(248, 81, 73, 0.5)';
    ctx.fillText('σ_u = ' + mat.sigmaUlt + ' MPa', margin.left + gw - 90, toY(utsStress) - 4);

    // Title
    ctx.fillStyle = 'rgba(255,255,255,0.6)';
    ctx.font = 'bold 12px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(useTrue ? 'True Stress-Strain Curve' : 'Stress-Strain Curve', 12, 20);

    // Legend
    ctx.font = '10px Inter, sans-serif';
    ctx.fillStyle = mat.color;
    ctx.fillText('● ' + state.material, margin.left + 10, margin.top + 14);
    if (mat2) {
        ctx.fillStyle = mat2.color;
        ctx.fillText('● ' + state.material2, margin.left + 100, margin.top + 14);
    }

    // Keyboard hint
    ctx.fillStyle = 'rgba(255,255,255,0.15)';
    ctx.font = '8px Inter, sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText('Press 1-7 to switch modules', w - 12, h - 6);
}

// ═══════════════════════════════════════════════════════════════
// Readouts
// ═══════════════════════════════════════════════════════════════

function updateReadouts() {
    const mat = getMat();
    const stress = calcStress(currentStrain, mat);
    const trueS = calcTrueStress(currentStrain, mat);

    $('material-e-readout').textContent = mat.E.toFixed(0) + ' GPa';
    $('material-sy-readout').textContent = mat.sigmaY + ' MPa';
    $('material-su-readout').textContent = mat.sigmaUlt + ' MPa';
    $('material-strain-readout').textContent = (currentStrain * 100).toFixed(2) + '%';
    $('material-stress-readout').textContent = (state.trueStress ? trueS : stress).toFixed(1) + ' MPa';

    // Toughness readout
    const toughnessEl = $('material-toughness-readout');
    if (toughnessEl) {
        const toughness = calcToughness(mat);
        toughnessEl.textContent = toughness.toFixed(1) + ' MJ/m³';
    }

    const warn = $('material-fracture-warning');
    if (currentStrain >= mat.strainFracture) {
        warn.classList.remove('hidden');
        fractured = true;
        running = false;
        $('material-start-btn').textContent = '▶ Start Test';
    } else {
        warn.classList.add('hidden');
    }
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    $('material-select').addEventListener('change', e => {
        state.material = e.target.value;
        resetTest();
    });

    $('material-compare').addEventListener('change', e => {
        state.compare = e.target.checked;
        $('material-compare-group').style.display = state.compare ? 'block' : 'none';
        resetTest();
    });

    $('material-select2').addEventListener('change', e => {
        state.material2 = e.target.value;
        resetTest();
    });

    $('material-strain-rate').addEventListener('input', e => {
        state.strainRate = parseFloat(e.target.value);
        $('material-strain-rate-val').textContent = state.strainRate + 'x';
    });

    // True stress toggle
    const trueStressEl = $('material-true-stress');
    if (trueStressEl) {
        trueStressEl.addEventListener('change', e => {
            state.trueStress = e.target.checked;
        });
    }

    $('material-start-btn').addEventListener('click', () => {
        if (fractured) resetTest();
        running = !running;
        $('material-start-btn').textContent = running ? '⏸ Pause' : '▶ Resume';
    });

    $('material-reset-btn').addEventListener('click', resetTest);
}

function resetTest() {
    running = false;
    currentStrain = 0;
    fractured = false;
    stressHistory = [];
    compareHistory = [];
    $('material-start-btn').textContent = '▶ Start Test';
    $('material-fracture-warning').classList.add('hidden');
    createSpecimen();
    updateReadouts();
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initMaterialModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    createSpecimen();
    createGrips();
    bindUI();

    registerModule('material', {
        activate() {
            group.visible = true;
            resetTest();
        },
        deactivate() {
            group.visible = false;
            running = false;
        },
        update(dt, elapsed) {
            if (running && !fractured) {
                currentStrain += dt * 0.02 * state.strainRate;

                const mat = getMat();
                const stress = calcStress(currentStrain, mat);
                stressHistory.push({ strain: currentStrain, stress });

                if (state.compare) {
                    const mat2 = TENSILE_MATERIALS[state.material2];
                    const stress2 = calcStress(currentStrain, mat2);
                    compareHistory.push({ strain: currentStrain, stress: stress2 });
                }

                if (currentStrain >= mat.strainFracture) {
                    fractured = true;
                    running = false;
                    $('material-start-btn').textContent = '▶ Start Test';
                }
            }

            deformSpecimen();
            drawStressStrainCurve();
            updateReadouts();
        },
    });
}
