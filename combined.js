// ═══════════════════════════════════════════════════════════════
// combined.js — Combined Loading Module
// Simulates Axial, Bending, and Torsion loads simultaneously
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, registerModule, MATERIALS, clamp, heatmapColor, formatSI, getCachedMaterial, disposeObject } from './app.js';

const $ = id => document.getElementById(id);
let group;
let shaftMesh, shaftGeom, shaftMat, originalPositions;
let fixedWallMesh;
let loadArrows = [];
let dirty = true;
let computeTimeout = null;

function requestComputation() {
    clearTimeout(computeTimeout);
    const setReadout = (id, val) => { const el = $(id); if (el) el.textContent = val; };
    setReadout('combined-sigma-readout', '...');
    setReadout('combined-tau-readout', '...');
    setReadout('combined-p1-readout', '...');
    setReadout('combined-p2-readout', '...');
    setReadout('combined-vm-readout', '...');
    const safetyEl = $('combined-safety-readout');
    if (safetyEl) {
        safetyEl.textContent = '...';
        safetyEl.className = 'readout-value';
    }
    const yieldWarn = $('combined-yield-warning');
    if (yieldWarn) yieldWarn.classList.add('hidden');

    computeTimeout = setTimeout(() => {
        dirty = true;
    }, 500);
}

const SHAFT_SEGS_RADIAL = 32;
const SHAFT_SEGS_HEIGHT = 80;

const state = {
    material: 'steel',
    length: 2.0,
    outerR: 0.05,
    innerR: 0,
    loadAxial: 0,     // N
    loadBending: 0,   // N
    loadTorsion: 0,   // N·m
    deformScale: 20,
};

function getMaterial() { return MATERIALS[state.material]; }
function getE() { return getMaterial().E; }
function getG() { return getMaterial().G; }

function getArea() {
    return Math.PI * (Math.pow(state.outerR, 2) - Math.pow(state.innerR, 2));
}

function getI() {
    return (Math.PI / 4) * (Math.pow(state.outerR, 4) - Math.pow(state.innerR, 4));
}

function getJ() {
    return (Math.PI / 2) * (Math.pow(state.outerR, 4) - Math.pow(state.innerR, 4));
}

// ═══════════════════════════════════════════════════════════════
// Combined Loading Calculations
// ═══════════════════════════════════════════════════════════════

function calcCombined() {
    const E = getE();
    const G = getG();
    const A = getArea();
    const I = getI();
    const J = getJ();
    const L = state.length;
    const r = state.outerR;

    const P = state.loadAxial;
    const V = state.loadBending;
    const T = state.loadTorsion;

    // Max Bending Moment is at the fixed support (x=0)
    const M_max = Math.abs(V) * L;

    // ----- Normal Stress (σ_x) -----
    // Axial normal stress
    const sigma_axial = P / A;
    // Maximum bending stress occurs at outer fibers (y = ±r)
    const sigma_bending = (M_max * r) / I;

    // We get the absolute maximum normal stress assuming both add up at the critical point
    const sigma_x_max = Math.abs(sigma_axial) + Math.abs(sigma_bending);

    // ----- Shear Stress (τ_xy) -----
    // Torsional shear stress (max at outer surface)
    const tau_torsion = (T * r) / J;
    // Transverse shear stress Q is max at neutral axis, but we want the critical stress point
    // Usually the most critical point for combined loading is at the outer surface where 
    // bending and torsion are maximal (transverse shear is 0 there).
    const tau_xy_max = Math.abs(tau_torsion);

    // ----- Principal Stresses and Von Mises -----
    // Using Mohr's Circle equations for the critical point
    const sigma_avg = sigma_x_max / 2;
    const R = Math.sqrt(Math.pow(sigma_x_max / 2, 2) + Math.pow(tau_xy_max, 2));

    const sigma_1 = sigma_avg + R;
    const sigma_2 = sigma_avg - R;

    // Von Mises stress (2D plane stress state at the surface)
    const sigma_vm = Math.sqrt(sigma_1 * sigma_1 - sigma_1 * sigma_2 + sigma_2 * sigma_2);

    // Safety factor
    const yieldStress = getMaterial().yieldStress;
    const safetyFactor = sigma_vm > 0 ? yieldStress / sigma_vm : Infinity;

    // ----- Deflections -----
    // Axial elongation
    const delta_L = (P * L) / (A * E);

    // Max bending deflection
    const delta_y = (V * Math.pow(L, 3)) / (3 * E * I);

    // Twist angle
    const phi = (T * L) / (G * J);

    return {
        sigma_x_max, tau_xy_max, sigma_1, sigma_2, sigma_vm, safetyFactor,
        delta_L, delta_y, phi
    };
}

// ═══════════════════════════════════════════════════════════════
// 3D Objects
// ═══════════════════════════════════════════════════════════════

function createShaft() {
    if (shaftMesh) {
        group.remove(shaftMesh);
        shaftGeom.dispose();
        shaftMat.dispose();
    }

    const mat = getMaterial();
    // Visual radius scaled for better 3D appearance relative to typical length
    const visualR = state.outerR * 5;
    const visualIR = state.innerR * 5;

    if (state.innerR > 0) {
        const pts = [];
        const nH = SHAFT_SEGS_HEIGHT;
        for (let i = 0; i <= nH; i++) {
            pts.push(new THREE.Vector2(visualIR, (i / nH) * state.length));
        }
        for (let i = nH; i >= 0; i--) {
            pts.push(new THREE.Vector2(visualR, (i / nH) * state.length));
        }
        shaftGeom = new THREE.LatheGeometry(pts, SHAFT_SEGS_RADIAL);
    } else {
        shaftGeom = new THREE.CylinderGeometry(visualR, visualR, state.length, SHAFT_SEGS_RADIAL, SHAFT_SEGS_HEIGHT, false);
    }

    shaftMat = new THREE.MeshStandardMaterial({
        color: mat.color,
        roughness: 0.35,
        metalness: 0.7,
        vertexColors: true,
    });

    shaftMesh = new THREE.Mesh(shaftGeom, shaftMat);

    if (state.innerR <= 0) {
        shaftMesh.rotation.z = -Math.PI / 2;
        shaftMesh.position.set(state.length / 2, 0.8, 0);
    } else {
        shaftMesh.rotation.z = -Math.PI / 2;
        shaftMesh.position.set(0, 0.8, 0); // Lathe geometry behaves slightly differently
    }

    shaftMesh.castShadow = true;
    shaftMesh.receiveShadow = true;
    group.add(shaftMesh);

    originalPositions = shaftGeom.attributes.position.array.slice();
    // Do not set dirty = true here; let requestComputation handle it
}

function createWall() {
    if (fixedWallMesh) { group.remove(fixedWallMesh); fixedWallMesh.geometry.dispose(); fixedWallMesh.material.dispose(); }

    const geo = new THREE.BoxGeometry(0.12, 1.5, 1.5);
    const mat = getCachedMaterial(0x444444, { roughness: 0.7, metalness: 0.2 });
    fixedWallMesh = new THREE.Mesh(geo, mat);
    fixedWallMesh.position.set(-0.06, 0.8, 0);
    fixedWallMesh.castShadow = true;
    group.add(fixedWallMesh);
}

function createLoadArrows() {
    loadArrows.forEach(a => disposeObject(a));
    loadArrows = [];

    const L = state.length;
    const P = state.loadAxial;
    const V = state.loadBending;
    const T = state.loadTorsion;
    const visualR = state.outerR * 5;

    const baseZ = 0;
    const baseY = 0.8;

    // Axial Arrow (X-axis)
    if (Math.abs(P) > 1) {
        const dir = new THREE.Vector3(P > 0 ? 1 : -1, 0, 0);
        // Start origin outside the specimen based on whether it is tension or compression
        const origin = new THREE.Vector3(L + (P > 0 ? 0.1 : 0.6), baseY, baseZ);
        const color = P > 0 ? 0x58a6ff : 0xf85149;
        const arrow = new THREE.ArrowHelper(dir, origin, 0.5, color, 0.12, 0.08);
        group.add(arrow);
        loadArrows.push(arrow);
    }

    // Transverse (Bending) Arrow (Y-axis)
    if (Math.abs(V) > 1) {
        const dir = new THREE.Vector3(0, V > 0 ? -1 : 1, 0);
        const origin = new THREE.Vector3(L, baseY + (V > 0 ? visualR + 0.6 : -visualR - 0.6), baseZ);
        const color = V > 0 ? 0xf85149 : 0x3fb950;
        const arrow = new THREE.ArrowHelper(dir, origin, 0.5, color, 0.12, 0.08);
        group.add(arrow);
        loadArrows.push(arrow);
    }

    // Torsion Arrow
    if (Math.abs(T) > 1) {
        const torusGeo = new THREE.TorusGeometry(visualR + 0.15, 0.03, 8, 32, Math.PI * 1.5);
        const color = T > 0 ? 0xd29922 : 0xa371f7;
        const torusMat = new THREE.MeshBasicMaterial({ color });
        const torqueArrow = new THREE.Mesh(torusGeo, torusMat);
        torqueArrow.position.set(L + 0.1, baseY, baseZ);
        torqueArrow.rotation.y = Math.PI / 2;
        group.add(torqueArrow);
        loadArrows.push(torqueArrow);

        const coneGeo = new THREE.ConeGeometry(0.06, 0.15, 8);
        const coneMat = new THREE.MeshBasicMaterial({ color });
        const cone = new THREE.Mesh(coneGeo, coneMat);
        cone.position.set(0, visualR + 0.15, 0);
        cone.rotation.z = T > 0 ? -Math.PI / 2 : Math.PI / 2;
        torqueArrow.add(cone);
    }
}

// ═══════════════════════════════════════════════════════════════
// Deformation & Stress Coloring
// ═══════════════════════════════════════════════════════════════

function deformShaft() {
    if (!shaftMesh || !dirty) return;
    dirty = false;

    const pos = shaftGeom.attributes.position;
    const L = state.length;
    const scale = state.deformScale;

    const E = getE();
    const I = getI();

    const { delta_L, phi } = calcCombined();

    const colors = new Float32Array(pos.count * 3);
    const yieldStress = getMaterial().yieldStress;

    for (let i = 0; i < pos.count; i++) {
        const ox = originalPositions[i * 3];
        const oy = originalPositions[i * 3 + 1];
        const oz = originalPositions[i * 3 + 2];

        let xAlongShaft, yLocal, zLocal, r, theta;

        if (state.innerR <= 0) {
            xAlongShaft = oy;
            yLocal = ox; // rotated cylinder
            zLocal = oz;
            r = Math.sqrt(ox * ox + oz * oz);
            theta = Math.atan2(oz, ox);
        } else {
            xAlongShaft = oz;
            yLocal = ox;
            zLocal = oy; // Lathe geometry mapping
            r = Math.sqrt(ox * ox + oy * oy);
            theta = Math.atan2(oy, ox);
        }

        const normX = xAlongShaft / L;

        // 1. Axial Extrapolation
        const axialDisp = delta_L * normX * scale;

        // 2. Bending Deflection
        // Deflection curve for cantilever with point load at end: v(x) = (Px^2)/(6EI) * (3L - x)
        let bendingDisp = 0;
        if (state.loadBending !== 0) {
            bendingDisp = (state.loadBending * xAlongShaft * xAlongShaft) / (6 * E * I) * (3 * L - xAlongShaft) * scale;
        }

        // 3. Torsional Twist
        const twistAngle = phi * normX * scale;
        const newTheta = theta + twistAngle;

        // Compute Local Stresses for Heatmap (simplified at this node)
        // Sigma X = P/A - (M*y)/I
        // M(x) = V * (L - x)
        const M_x = state.loadBending * (L - xAlongShaft);

        let sig_x = 0;
        let tau_xy = 0;

        // Approximate actual physical radius without visual scaling factor for stress calc
        const actualR = r / 5;
        const actualY = actualR * Math.cos(theta); // approximate local y from neutral axis

        sig_x = (state.loadAxial / getArea()) - ((M_x * actualY) / I);
        tau_xy = (state.loadTorsion * actualR) / getJ();

        // Von Mises at node
        const node_vm = Math.sqrt(sig_x * sig_x + 3 * tau_xy * tau_xy);

        const t = clamp(node_vm / yieldStress, 0, 1);
        const c = heatmapColor(t);
        colors[i * 3] = c.r;
        colors[i * 3 + 1] = c.g;
        colors[i * 3 + 2] = c.b;

        // Apply displaced coordinates
        let newX, newY, newZ;

        if (state.innerR <= 0) {
            newX = r * Math.cos(newTheta);
            newY = oy;
            newZ = r * Math.sin(newTheta);

            // Re-apply rotation of the cylinder mesh intrinsically if needed, but easier to map directly
            pos.array[i * 3] = newX;
            pos.array[i * 3 + 1] = newY + axialDisp; // stretches along Y which is visually X
            pos.array[i * 3 + 2] = newZ + bendingDisp; // bends along Z
        } else {
            newX = r * Math.cos(newTheta);
            newY = r * Math.sin(newTheta);
            newZ = oz;

            pos.array[i * 3] = newX;
            pos.array[i * 3 + 1] = newY + bendingDisp;
            pos.array[i * 3 + 2] = newZ + axialDisp;
        }
    }

    pos.needsUpdate = true;
    shaftGeom.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    shaftGeom.computeVertexNormals();

    updateReadouts();
}

function updateReadouts() {
    const res = calcCombined();

    $('combined-sigma-readout').textContent = formatSI(res.sigma_x_max, 'Pa');
    $('combined-tau-readout').textContent = formatSI(res.tau_xy_max, 'Pa');
    $('combined-p1-readout').textContent = formatSI(res.sigma_1, 'Pa');
    $('combined-p2-readout').textContent = formatSI(res.sigma_2, 'Pa');
    $('combined-vm-readout').textContent = formatSI(res.sigma_vm, 'Pa');

    const safetyEl = $('combined-safety-readout');
    if (safetyEl) {
        if (res.safetyFactor === Infinity || res.safetyFactor > 99) {
            safetyEl.textContent = '—';
            safetyEl.className = 'readout-value';
        } else {
            safetyEl.textContent = res.safetyFactor.toFixed(2);
            safetyEl.className = 'readout-value ' + (res.safetyFactor >= 2 ? 'safe' : res.safetyFactor >= 1 ? 'warning' : 'danger');
        }
    }

    const yieldWarn = $('combined-yield-warning');
    if (res.sigma_vm > getMaterial().yieldStress) {
        yieldWarn.classList.remove('hidden');
    } else {
        yieldWarn.classList.add('hidden');
    }

    drawBendingMomentGraph();
}

function drawBendingMomentGraph() {
    const canvas = $('bending-moment-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;

    ctx.clearRect(0, 0, width, height);

    const L = state.length;
    const V = state.loadBending;
    const maxM = Math.abs(V * L);

    // Draw neutral axis
    ctx.beginPath();
    ctx.moveTo(0, height / 2);
    ctx.lineTo(width, height / 2);
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.4)';
    ctx.lineWidth = 1;
    ctx.stroke();

    if (maxM < 1e-6) return;

    // Draw Moment diagram
    const startY = height / 2 - (V * L > 0 ? 1 : -1) * (height / 2 - 15);

    ctx.beginPath();
    ctx.moveTo(0, startY);
    ctx.lineTo(width, height / 2);
    ctx.lineTo(width, height / 2);
    ctx.lineTo(0, height / 2);
    ctx.closePath();

    ctx.fillStyle = V > 0 ? 'rgba(248, 81, 73, 0.4)' : 'rgba(63, 185, 80, 0.4)';
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(0, startY);
    ctx.lineTo(width, height / 2);
    ctx.strokeStyle = V > 0 ? '#f85149' : '#3fb950';
    ctx.lineWidth = 2;
    ctx.stroke();

    // Label max moment at fixed end
    ctx.fillStyle = '#ffffff';
    ctx.font = '12px var(--mono, monospace)';
    ctx.textAlign = 'left';
    ctx.fillText(formatSI(maxM, 'N·m'), 8, startY < height / 2 ? startY - 8 : startY + 14);
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    $('combined-material').addEventListener('change', e => {
        state.material = e.target.value;
        createShaft(); requestComputation();
    });

    $('combined-length').addEventListener('input', e => {
        state.length = parseFloat(e.target.value);
        $('combined-length-val').textContent = state.length.toFixed(1) + ' m';
        createShaft(); createWall(); createLoadArrows(); requestComputation();
    });

    $('combined-radius').addEventListener('input', e => {
        state.outerR = parseInt(e.target.value) / 1000;
        $('combined-radius-val').textContent = parseInt(e.target.value) + ' mm';
        if (state.innerR >= state.outerR) {
            state.innerR = state.outerR - 0.005;
            $('combined-inner-radius').value = state.innerR * 1000;
            $('combined-inner-radius-val').textContent = (state.innerR * 1000) + ' mm';
        }
        createShaft(); createLoadArrows(); requestComputation();
    });

    $('combined-inner-radius').addEventListener('input', e => {
        state.innerR = parseInt(e.target.value) / 1000;
        $('combined-inner-radius-val').textContent = parseInt(e.target.value) + ' mm';
        if (state.innerR >= state.outerR) {
            state.innerR = state.outerR - 0.005;
        }
        createShaft(); createLoadArrows(); requestComputation();
    });

    $('combined-load-axial').addEventListener('input', e => {
        state.loadAxial = parseFloat(e.target.value) * 1000; // slider in kN
        $('combined-load-axial-val').textContent = parseFloat(e.target.value).toFixed(1) + ' kN';
        createLoadArrows(); requestComputation();
    });

    $('combined-load-bending').addEventListener('input', e => {
        state.loadBending = parseFloat(e.target.value) * 1000; // slider in kN
        $('combined-load-bending-val').textContent = parseFloat(e.target.value).toFixed(1) + ' kN';
        createLoadArrows(); requestComputation();
    });

    $('combined-load-torsion').addEventListener('input', e => {
        state.loadTorsion = parseFloat(e.target.value) * 1000; // slider in kN.m
        $('combined-load-torsion-val').textContent = parseFloat(e.target.value).toFixed(1) + ' kN·m';
        createLoadArrows(); requestComputation();
    });

    $('combined-deform-scale').addEventListener('input', e => {
        state.deformScale = parseInt(e.target.value);
        $('combined-deform-scale-val').textContent = state.deformScale + 'x';
        requestComputation();
    });

    $('combined-reset-btn').addEventListener('click', () => {
        state.material = 'steel';
        state.length = 2.0;
        state.outerR = 0.05;
        state.innerR = 0;
        state.loadAxial = 0;
        state.loadBending = 0;
        state.loadTorsion = 0;
        state.deformScale = 20;

        $('combined-material').value = 'steel';
        $('combined-length').value = 2; $('combined-length-val').textContent = '2.0 m';
        $('combined-radius').value = 50; $('combined-radius-val').textContent = '50 mm';
        $('combined-inner-radius').value = 0; $('combined-inner-radius-val').textContent = '0 mm';
        $('combined-load-axial').value = 0; $('combined-load-axial-val').textContent = '0.0 kN';
        $('combined-load-bending').value = 0; $('combined-load-bending-val').textContent = '0.0 kN';
        $('combined-load-torsion').value = 0; $('combined-load-torsion-val').textContent = '0.0 kN·m';
        $('combined-deform-scale').value = 20; $('combined-deform-scale-val').textContent = '20x';

        // Reattach styles to sliders since programmatic changes don't trigger input event listener properly for gradients
        document.querySelectorAll('#combined-controls input[type="range"]').forEach(s => {
            if (window.updateSliderFill) window.updateSliderFill(s);
        });

        createShaft(); createWall(); createLoadArrows(); requestComputation();
    });
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initCombinedModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    createShaft();
    createWall();
    createLoadArrows();
    bindUI();

    registerModule('combined', {
        activate() {
            group.visible = true;
            requestComputation();
        },
        deactivate() {
            group.visible = false;
        },
        update(dt, elapsed) {
            deformShaft();
        },
    });
}
