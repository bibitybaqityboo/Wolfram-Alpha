// ═══════════════════════════════════════════════════════════════
// column.js — Column Buckling Module
// Euler's formula with animated buckling mode shapes
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, registerModule, MATERIALS, clamp, formatSI, getCachedMaterial } from './app.js';

const $ = id => document.getElementById(id);
let group;
let columnMesh, columnGeom, columnMat, originalPositions;
let topPlateMesh, bottomPlateMesh;
let loadArrow;
let wallMeshes = [];
let dirty = true;
let buckleAnim = 0;

const COL_SEGS = 80;

const END_CONDITIONS = {
    'pinned-pinned': { K: 1.0, label: 'K = 1.0' },
    'fixed-free': { K: 2.0, label: 'K = 2.0' },
    'fixed-pinned': { K: 0.7, label: 'K = 0.7' },
    'fixed-fixed': { K: 0.5, label: 'K = 0.5' },
};

const state = {
    material: 'steel',
    endCond: 'pinned-pinned',
    length: 3.0,
    width: 0.05,
    depth: 0.05,
    load: 50000,   // N
    mode: 1,
};

function getI() {
    // Buckling occurs about the weaker axis — use minimum I
    const Ix = (state.width * Math.pow(state.depth, 3)) / 12;
    const Iy = (state.depth * Math.pow(state.width, 3)) / 12;
    return Math.min(Ix, Iy);
}

function getE() {
    return MATERIALS[state.material].E;
}

function calcBuckling() {
    const E = getE();
    const I = getI();
    const L = state.length;
    const K = END_CONDITIONS[state.endCond].K;
    const Le = K * L;
    const A = state.width * state.depth;
    const sigmaY = MATERIALS[state.material].yieldStress;

    const n = state.mode;
    const rg = Math.sqrt(I / A); // radius of gyration
    const slenderness = Le / rg;

    // Euler critical load
    const PcrEuler = n * n * Math.PI * Math.PI * E * I / (Le * Le);

    // Transition slenderness: below this, use Johnson parabola (inelastic buckling)
    const slendernessTransition = Math.sqrt(2 * Math.PI * Math.PI * E / sigmaY);

    let Pcr;
    if (slenderness >= slendernessTransition || n > 1) {
        // Long column (Euler) or higher modes
        Pcr = PcrEuler;
    } else {
        // Intermediate column (Johnson parabola)
        // P_cr = σ_y * A * (1 - (σ_y * (Le/r)²) / (4π²E))
        Pcr = sigmaY * A * (1 - (sigmaY * slenderness * slenderness) / (4 * Math.PI * Math.PI * E));
    }

    const safety = state.load > 0 ? Pcr / state.load : Infinity;
    const isJohnson = slenderness < slendernessTransition && n === 1;

    return { Pcr, PcrEuler, safety, slenderness, slendernessTransition, Le, K, I, A, rg, isJohnson };
}

// ═══════════════════════════════════════════════════════════════
// 3D Objects
// ═══════════════════════════════════════════════════════════════

function createColumn() {
    if (columnMesh) {
        group.remove(columnMesh);
        columnGeom.dispose();
        columnMat.dispose();
    }

    const mat = MATERIALS[state.material];
    const w = Math.max(state.width * 4, 0.08);
    const d = Math.max(state.depth * 4, 0.08);

    columnGeom = new THREE.BoxGeometry(w, state.length, d, 4, COL_SEGS, 4);
    columnMat = new THREE.MeshStandardMaterial({
        color: mat.color,
        roughness: 0.4,
        metalness: 0.6,
    });
    columnMesh = new THREE.Mesh(columnGeom, columnMat);
    columnMesh.position.set(0, state.length / 2, 0);
    columnMesh.castShadow = true;
    group.add(columnMesh);

    originalPositions = columnGeom.attributes.position.array.slice();
    dirty = true;
}

function createEndConditions() {
    wallMeshes.forEach(m => { group.remove(m); m.geometry.dispose(); m.material.dispose(); });
    wallMeshes = [];

    if (topPlateMesh) { group.remove(topPlateMesh); topPlateMesh.geometry.dispose(); topPlateMesh.material.dispose(); }
    if (bottomPlateMesh) { group.remove(bottomPlateMesh); bottomPlateMesh.geometry.dispose(); bottomPlateMesh.material.dispose(); }

    const L = state.length;
    const plateMat = getCachedMaterial(0x555555, { roughness: 0.6, metalness: 0.3 });

    // Bottom support
    const bottomGeo = new THREE.BoxGeometry(0.5, 0.06, 0.5);
    bottomPlateMesh = new THREE.Mesh(bottomGeo, plateMat.clone());
    bottomPlateMesh.position.set(0, -0.03, 0);
    bottomPlateMesh.castShadow = true;
    group.add(bottomPlateMesh);

    // Top plate
    const topGeo = new THREE.BoxGeometry(0.5, 0.06, 0.5);
    topPlateMesh = new THREE.Mesh(topGeo, plateMat.clone());
    topPlateMesh.position.set(0, L + 0.03, 0);
    topPlateMesh.castShadow = true;
    group.add(topPlateMesh);

    const ec = state.endCond;

    // Fixed wall visualizations
    function makeWall(y, flipX) {
        const geo = new THREE.BoxGeometry(0.08, 0.5, 0.5);
        const mat = getCachedMaterial(0x444444, { roughness: 0.7, metalness: 0.2 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(flipX ? -0.3 : 0.3, y, 0);
        mesh.castShadow = true;
        group.add(mesh);
        wallMeshes.push(mesh);
    }

    function makePinSymbol(y) {
        const geo = new THREE.SphereGeometry(0.05, 16, 16);
        const mat = getCachedMaterial(0x3fb950, { roughness: 0.4, metalness: 0.5 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(0, y, 0);
        group.add(mesh);
        wallMeshes.push(mesh);

        // Triangle underneath
        const shape = new THREE.Shape();
        shape.moveTo(-0.1, 0);
        shape.lineTo(0.1, 0);
        shape.lineTo(0, 0.15);
        shape.closePath();
        const triGeo = new THREE.ExtrudeGeometry(shape, { depth: 0.08, bevelEnabled: false });
        const triMat = getCachedMaterial(0x3fb950, { roughness: 0.5, metalness: 0.3 });
        const triMesh = new THREE.Mesh(triGeo, triMat);
        triMesh.position.set(0, y - 0.15, -0.04);
        group.add(triMesh);
        wallMeshes.push(triMesh);
    }

    if (ec === 'pinned-pinned') {
        makePinSymbol(0);
        makePinSymbol(L);
    } else if (ec === 'fixed-free') {
        makeWall(0.25, false);
        makeWall(0.25, true);
    } else if (ec === 'fixed-pinned') {
        makeWall(0.25, false);
        makeWall(0.25, true);
        makePinSymbol(L);
    } else if (ec === 'fixed-fixed') {
        makeWall(0.25, false);
        makeWall(0.25, true);
        makeWall(L - 0.25, false);
        makeWall(L - 0.25, true);
    }
}

function createLoadArrow() {
    if (loadArrow) group.remove(loadArrow);
    if (state.load <= 0) return;

    const mag = clamp(state.load / 100000, 0.3, 1.5);
    const dir = new THREE.Vector3(0, -1, 0);
    const origin = new THREE.Vector3(0, state.length + 0.1 + mag, 0);
    const color = 0xf85149;
    loadArrow = new THREE.ArrowHelper(dir, origin, mag, color, 0.12, 0.08);
    group.add(loadArrow);
}

// ═══════════════════════════════════════════════════════════════
// Buckling Deformation
// ═══════════════════════════════════════════════════════════════

function deformColumn(elapsed) {
    if (!columnMesh) return;

    const pos = columnGeom.attributes.position;
    const L = state.length;
    const { Pcr, safety } = calcBuckling();
    const n = state.mode;

    // Animate buckling if load > Pcr
    const isBuckling = state.load >= Pcr && state.load > 0;
    const buckleAmplitude = isBuckling ?
        clamp((state.load / Pcr - 1) * 0.3, 0, 0.5) + 0.1 * Math.sin(elapsed * 3) :
        0.02 * Math.sin(elapsed * 2); // subtle sway even when stable

    for (let i = 0; i < pos.count; i++) {
        const ox = originalPositions[i * 3];
        const oy = originalPositions[i * 3 + 1];
        const oz = originalPositions[i * 3 + 2];

        // y is along column (0 at center), normalize to 0..1
        const yNorm = (oy / L) + 0.5;

        // Buckling mode shape: sin(n * pi * y/L)
        let dx = 0;
        const ec = state.endCond;

        if (ec === 'pinned-pinned') {
            dx = buckleAmplitude * Math.sin(n * Math.PI * yNorm);
        } else if (ec === 'fixed-free') {
            dx = buckleAmplitude * (1 - Math.cos(n * Math.PI * yNorm / 2));
        } else if (ec === 'fixed-pinned') {
            // Correct mode shape: tan(βL) = βL → β ≈ 4.4934/L for n=1
            // φ(y) = sin(β·y) - (sin(β·L)/(β·L))·(β·y)  (zero slope at fixed, zero disp at both ends)
            const beta = (4.4934 * n) / 1.0; // normalized β (yNorm is 0..1)
            const sinBL = Math.sin(beta);
            const phi = Math.sin(beta * yNorm) - (sinBL / beta) * (beta * yNorm);
            // Normalize so max is 1
            const phiMax = 0.637; // precomputed max of this shape
            dx = buckleAmplitude * phi / phiMax;
        } else if (ec === 'fixed-fixed') {
            dx = buckleAmplitude * (1 - Math.cos(2 * n * Math.PI * yNorm)) / 2;
        }

        pos.array[i * 3] = ox + dx;
        pos.array[i * 3 + 1] = oy;
        pos.array[i * 3 + 2] = oz;

        // Color the column based on safety factor
        // We'll set it up with vertex colors
    }

    pos.needsUpdate = true;

    // Color based on safety
    if (isBuckling) {
        columnMat.color.setHex(0xf85149);
        columnMat.emissive.setHex(0x331111);
    } else if (safety < 2) {
        columnMat.color.setHex(0xd29922);
        columnMat.emissive.setHex(0x221100);
    } else {
        columnMat.color.setHex(MATERIALS[state.material].color);
        columnMat.emissive.setHex(0x000000);
    }

    columnGeom.computeVertexNormals();
    updateReadouts();
}

function updateReadouts() {
    const { Pcr, safety, slenderness, Le, isJohnson } = calcBuckling();

    $('column-pcr-readout').textContent = formatSI(Pcr, 'N');
    $('column-safety-readout').textContent = safety === Infinity ? '∞' : safety.toFixed(2);
    $('column-slender-readout').textContent = slenderness.toFixed(1);
    $('column-kl-readout').textContent = Le.toFixed(2) + ' m';

    // Show analysis mode (Euler vs Johnson)
    const analysisEl = $('column-analysis-readout');
    if (analysisEl) analysisEl.textContent = isJohnson ? 'Johnson' : 'Euler';

    // Buckle warning
    const warn = $('column-buckle-warning');
    if (state.load >= Pcr && state.load > 0) {
        warn.classList.remove('hidden');
    } else {
        warn.classList.add('hidden');
    }

    // Color safety readout
    const safetyReadout = $('column-safety-readout');
    if (safety < 1) {
        safetyReadout.style.color = '#f85149';
    } else if (safety < 2) {
        safetyReadout.style.color = '#d29922';
    } else {
        safetyReadout.style.color = '#3fb950';
    }
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    $('column-material').addEventListener('change', e => {
        state.material = e.target.value;
        createColumn(); createEndConditions(); dirty = true;
    });

    $('column-end-cond').addEventListener('change', e => {
        state.endCond = e.target.value;
        createColumn(); createEndConditions(); dirty = true;
    });

    $('column-length').addEventListener('input', e => {
        state.length = parseFloat(e.target.value);
        $('column-length-val').textContent = state.length.toFixed(1) + ' m';
        createColumn(); createEndConditions(); createLoadArrow(); dirty = true;
    });

    $('column-width').addEventListener('input', e => {
        state.width = parseInt(e.target.value) / 1000;
        $('column-width-val').textContent = parseInt(e.target.value) + ' mm';
        createColumn(); dirty = true;
    });

    $('column-depth').addEventListener('input', e => {
        state.depth = parseInt(e.target.value) / 1000;
        $('column-depth-val').textContent = parseInt(e.target.value) + ' mm';
        createColumn(); dirty = true;
    });

    $('column-load').addEventListener('input', e => {
        state.load = parseInt(e.target.value) * 1000;
        $('column-load-val').textContent = parseInt(e.target.value) + ' kN';
        createLoadArrow(); dirty = true;
    });

    $('column-mode').addEventListener('input', e => {
        state.mode = parseInt(e.target.value);
        $('column-mode-val').textContent = state.mode;
        dirty = true;
    });

    $('column-reset-btn').addEventListener('click', () => {
        state.material = 'steel'; state.endCond = 'pinned-pinned';
        state.length = 3; state.width = 0.05; state.depth = 0.05;
        state.load = 50000; state.mode = 1;

        $('column-material').value = 'steel';
        $('column-end-cond').value = 'pinned-pinned';
        $('column-length').value = 3; $('column-length-val').textContent = '3.0 m';
        $('column-width').value = 50; $('column-width-val').textContent = '50 mm';
        $('column-depth').value = 50; $('column-depth-val').textContent = '50 mm';
        $('column-load').value = 50; $('column-load-val').textContent = '50 kN';
        $('column-mode').value = 1; $('column-mode-val').textContent = '1';

        createColumn(); createEndConditions(); createLoadArrow(); dirty = true;
    });
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initColumnModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    createColumn();
    createEndConditions();
    createLoadArrow();
    bindUI();

    registerModule('column', {
        activate() {
            group.visible = true;
            dirty = true;
        },
        deactivate() {
            group.visible = false;
        },
        update(dt, elapsed) {
            deformColumn(elapsed);
        },
    });
}
