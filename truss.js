// ═══════════════════════════════════════════════════════════════
// truss.js — Truss Analysis Module
// Interactive 2D truss builder with Direct Stiffness Method solver
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, camera, renderer, orbitControls, registerModule, MATERIALS, clamp, formatSI, getCachedMaterial } from './app.js';

const $ = id => document.getElementById(id);
let group;
let dirty = false;

// ═══════════════════════════════════════════════════════════════
// Truss Solver (Direct Stiffness Method)
// ═══════════════════════════════════════════════════════════════

class TrussSolver {
    static solve(nodes, members, supports, loads) {
        const nNodes = nodes.length;
        const nDOF = nNodes * 2;
        if (nDOF === 0) return { error: 'No nodes' };

        // Initialize global stiffness matrix
        const K = Array.from({ length: nDOF }, () => new Float64Array(nDOF));
        const F = new Float64Array(nDOF);

        const E = 200e9;
        const A = 0.001; // 1000 mm²

        // Assemble global stiffness
        for (const m of members) {
            const n1 = nodes[m.a];
            const n2 = nodes[m.b];
            const dx = n2.x - n1.x;
            const dy = n2.y - n1.y;
            const L = Math.sqrt(dx * dx + dy * dy);
            if (L < 1e-6) continue;

            const c = dx / L;
            const s = dy / L;
            const k = E * A / L;

            const cc = c * c * k;
            const ss = s * s * k;
            const cs = c * s * k;

            const dofs = [m.a * 2, m.a * 2 + 1, m.b * 2, m.b * 2 + 1];
            const ke = [
                [cc, cs, -cc, -cs],
                [cs, ss, -cs, -ss],
                [-cc, -cs, cc, cs],
                [-cs, -ss, cs, ss],
            ];

            for (let i = 0; i < 4; i++) {
                for (let j = 0; j < 4; j++) {
                    K[dofs[i]][dofs[j]] += ke[i][j];
                }
            }
        }

        // Apply loads
        for (const l of loads) {
            F[l.nodeId * 2] += l.fx;
            F[l.nodeId * 2 + 1] += l.fy;
        }

        // Apply boundary conditions (penalty method)
        const penalty = 1e20;
        for (const s of supports) {
            const dofX = s.nodeId * 2;
            const dofY = s.nodeId * 2 + 1;
            if (s.type === 'pin') {
                K[dofX][dofX] += penalty;
                K[dofY][dofY] += penalty;
            } else if (s.type === 'roller') {
                K[dofY][dofY] += penalty;
            }
        }

        // Solve K*u = F using Gaussian elimination
        const u = this._gaussSolve(K, F, nDOF);
        if (!u) return { error: 'Singular matrix' };

        // Calculate member forces
        const memberForces = [];
        for (const m of members) {
            const n1 = nodes[m.a];
            const n2 = nodes[m.b];
            const dx = n2.x - n1.x;
            const dy = n2.y - n1.y;
            const L = Math.sqrt(dx * dx + dy * dy);
            if (L < 1e-6) { memberForces.push(0); continue; }

            const c = dx / L;
            const s = dy / L;

            const du = u[m.b * 2] - u[m.a * 2];
            const dv = u[m.b * 2 + 1] - u[m.a * 2 + 1];
            const force = (E * A / L) * (c * du + s * dv);
            memberForces.push(force);
        }

        return { displacements: u, memberForces };
    }

    static _gaussSolve(A, b, n) {
        const M = A.map(row => [...row]);
        const rhs = [...b];

        for (let col = 0; col < n; col++) {
            let maxRow = col;
            let maxVal = Math.abs(M[col][col]);
            for (let row = col + 1; row < n; row++) {
                if (Math.abs(M[row][col]) > maxVal) {
                    maxVal = Math.abs(M[row][col]);
                    maxRow = row;
                }
            }
            if (maxVal < 1e-30) return null;

            [M[col], M[maxRow]] = [M[maxRow], M[col]];
            [rhs[col], rhs[maxRow]] = [rhs[maxRow], rhs[col]];

            for (let row = col + 1; row < n; row++) {
                const factor = M[row][col] / M[col][col];
                for (let j = col; j < n; j++) {
                    M[row][j] -= factor * M[col][j];
                }
                rhs[row] -= factor * rhs[col];
            }
        }

        const x = new Float64Array(n);
        for (let i = n - 1; i >= 0; i--) {
            let sum = rhs[i];
            for (let j = i + 1; j < n; j++) {
                sum -= M[i][j] * x[j];
            }
            x[i] = sum / M[i][i];
        }
        return x;
    }
}

// ═══════════════════════════════════════════════════════════════
// Truss Builder
// ═══════════════════════════════════════════════════════════════

let nodes = [];
let members = [];
let supports = [];
let loads = [];
let result = null;

let currentTool = 'node';
let memberStart = null;
let deformScale = 50;

// 3D meshes
let nodeMeshes = [];
let memberMeshes = [];
let supportMeshGroup;
let loadMeshGroup;
let deformedGroup;
let gridMesh;

const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
const gridPlane = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0);

function snapToGrid(x, y) {
    return {
        x: Math.round(x * 2) / 2,
        y: Math.round(y * 2) / 2,
    };
}

function getWorldPos(e) {
    const rect = renderer.domElement.getBoundingClientRect();
    mouse.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    raycaster.setFromCamera(mouse, camera);
    const intersection = new THREE.Vector3();
    raycaster.ray.intersectPlane(gridPlane, intersection);
    return intersection;
}

function findNodeNear(x, y, threshold = 0.4) {
    for (let i = 0; i < nodes.length; i++) {
        const dx = nodes[i].x - x;
        const dy = nodes[i].y - y;
        if (Math.sqrt(dx * dx + dy * dy) < threshold) return i;
    }
    return -1;
}

// ── Create visual meshes ──

function createNodeMesh(n) {
    const geo = new THREE.SphereGeometry(0.12, 16, 16);
    const mat = getCachedMaterial(0x58a6ff, { roughness: 0.3, metalness: 0.6, emissive: 0x112244, emissiveIntensity: 0.3 });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(n.x, n.y, 0);
    mesh.castShadow = true;
    group.add(mesh);
    return mesh;
}

function createMemberMesh(nA, nB) {
    const dx = nB.x - nA.x;
    const dy = nB.y - nA.y;
    const L = Math.sqrt(dx * dx + dy * dy);
    const angle = Math.atan2(dy, dx);

    const geo = new THREE.CylinderGeometry(0.04, 0.04, L, 8);
    const mat = getCachedMaterial(0x8899aa, { roughness: 0.4, metalness: 0.6 });
    const mesh = new THREE.Mesh(geo, mat);

    mesh.position.set((nA.x + nB.x) / 2, (nA.y + nB.y) / 2, 0);
    mesh.rotation.z = angle - Math.PI / 2;
    mesh.castShadow = true;
    group.add(mesh);
    return mesh;
}

function rebuildVisuals() {
    // Clear existing
    nodeMeshes.forEach(m => { group.remove(m); m.geometry.dispose(); m.material.dispose(); });
    memberMeshes.forEach(m => { group.remove(m); m.geometry.dispose(); m.material.dispose(); });
    nodeMeshes = [];
    memberMeshes = [];

    // Rebuild nodes
    for (const n of nodes) {
        nodeMeshes.push(createNodeMesh(n));
    }

    // Rebuild members
    for (const m of members) {
        memberMeshes.push(createMemberMesh(nodes[m.a], nodes[m.b]));
    }

    // Supports
    while (supportMeshGroup.children.length) {
        const c = supportMeshGroup.children[0];
        supportMeshGroup.remove(c);
        if (c.geometry) c.geometry.dispose();
        if (c.material) c.material.dispose();
    }

    for (const s of supports) {
        const n = nodes[s.nodeId];
        if (s.type === 'pin') {
            const shape = new THREE.Shape();
            shape.moveTo(-0.15, 0);
            shape.lineTo(0.15, 0);
            shape.lineTo(0, 0.2);
            shape.closePath();
            const geo = new THREE.ExtrudeGeometry(shape, { depth: 0.08, bevelEnabled: false });
            const mat = getCachedMaterial(0x3fb950, { roughness: 0.5, metalness: 0.3 });
            const mesh = new THREE.Mesh(geo, mat);
            mesh.position.set(n.x, n.y - 0.2, -0.04);
            supportMeshGroup.add(mesh);
        } else {
            // Roller
            const geo = new THREE.CylinderGeometry(0.08, 0.08, 0.1, 16);
            const mat = getCachedMaterial(0xd29922, { roughness: 0.4, metalness: 0.5 });
            const mesh = new THREE.Mesh(geo, mat);
            mesh.rotation.x = Math.PI / 2;
            mesh.position.set(n.x, n.y - 0.12, 0);
            supportMeshGroup.add(mesh);
        }
    }

    // Loads
    while (loadMeshGroup.children.length) {
        const c = loadMeshGroup.children[0];
        loadMeshGroup.remove(c);
    }

    for (const l of loads) {
        const n = nodes[l.nodeId];
        const mag = Math.sqrt(l.fx * l.fx + l.fy * l.fy);
        if (mag < 1) continue;
        const dir = new THREE.Vector3(l.fx, l.fy, 0).normalize();
        const arrowLen = clamp(mag / 50000, 0.3, 1.5);
        const origin = new THREE.Vector3(n.x, n.y, 0).sub(dir.clone().multiplyScalar(arrowLen));
        const arrow = new THREE.ArrowHelper(dir, origin, arrowLen, 0xf85149, 0.12, 0.08);
        loadMeshGroup.add(arrow);
    }

    updateCounts();
}

function showDeformed() {
    // Clear deformed
    while (deformedGroup.children.length) {
        const c = deformedGroup.children[0];
        deformedGroup.remove(c);
        if (c.geometry) c.geometry.dispose();
        if (c.material) c.material.dispose();
    }

    if (!result || result.error) return;

    const u = result.displacements;
    const forces = result.memberForces;

    // Find max force for color scaling
    let maxForce = 0;
    for (const f of forces) maxForce = Math.max(maxForce, Math.abs(f));
    if (maxForce < 1) maxForce = 1;

    // Deformed members
    for (let i = 0; i < members.length; i++) {
        const m = members[i];
        const nA = nodes[m.a];
        const nB = nodes[m.b];
        const scale = deformScale;

        const ax = nA.x + u[m.a * 2] * scale;
        const ay = nA.y + u[m.a * 2 + 1] * scale;
        const bx = nB.x + u[m.b * 2] * scale;
        const by = nB.y + u[m.b * 2 + 1] * scale;

        const dx = bx - ax;
        const dy = by - ay;
        const L = Math.sqrt(dx * dx + dy * dy);
        const angle = Math.atan2(dy, dx);

        const force = forces[i];
        const t = Math.abs(force) / maxForce;
        let color;
        if (force > 0) {
            color = new THREE.Color(0x58a6ff); // tension: blue
        } else {
            color = new THREE.Color(0xf85149); // compression: red
        }

        const geo = new THREE.CylinderGeometry(0.06, 0.06, L, 8);
        const mat = new THREE.MeshStandardMaterial({
            color,
            roughness: 0.3,
            metalness: 0.5,
            transparent: true,
            opacity: 0.5 + t * 0.5,
        });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set((ax + bx) / 2, (ay + by) / 2, 0.1);
        mesh.rotation.z = angle - Math.PI / 2;
        deformedGroup.add(mesh);
    }

    // Deformed nodes
    for (let i = 0; i < nodes.length; i++) {
        const scale = deformScale;
        const nx = nodes[i].x + u[i * 2] * scale;
        const ny = nodes[i].y + u[i * 2 + 1] * scale;

        const geo = new THREE.SphereGeometry(0.1, 12, 12);
        const mat = getCachedMaterial(0xa371f7, { roughness: 0.3, metalness: 0.5 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(nx, ny, 0.1);
        deformedGroup.add(mesh);
    }
}

function analyze() {
    if (nodes.length < 2 || members.length < 1) {
        updateStatus('Need at least 2 nodes and 1 member', 'error');
        return;
    }
    if (supports.length < 1) {
        updateStatus('Need at least 1 support', 'error');
        return;
    }

    result = TrussSolver.solve(nodes, members, supports, loads);

    if (result.error) {
        updateStatus('Error: ' + result.error, 'error');
        return;
    }

    showDeformed();
    updateResultReadouts();
    updateStatus('Analysis complete ✓', 'success');
}

function updateCounts() {
    $('truss-nodes-readout').textContent = nodes.length;
    $('truss-members-readout').textContent = members.length;
}

function updateResultReadouts() {
    if (!result || result.error) return;

    let maxForce = 0;
    for (const f of result.memberForces) maxForce = Math.max(maxForce, Math.abs(f));
    $('truss-maxforce-readout').textContent = formatSI(maxForce, 'N');

    let maxDisp = 0;
    for (let i = 0; i < result.displacements.length; i++) {
        maxDisp = Math.max(maxDisp, Math.abs(result.displacements[i]));
    }
    $('truss-maxdisp-readout').textContent = (maxDisp * 1000).toFixed(2) + ' mm';
}

function updateStatus(msg, type = '') {
    const el = $('truss-status');
    el.textContent = msg;
    el.className = 'status-bar' + (type ? ' ' + type : '');
}

// ═══════════════════════════════════════════════════════════════
// Templates
// ═══════════════════════════════════════════════════════════════

function loadTemplate(name) {
    clearAll();

    if (name === 'pratt') {
        const spans = 6;
        const h = 2;
        const w = 1.5;
        // Bottom chord
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: 0 });
        // Top chord
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: h });
        // Bottom chord members
        for (let i = 0; i < spans; i++) members.push({ a: i, b: i + 1 });
        // Top chord members
        for (let i = 0; i < spans; i++) members.push({ a: spans + 1 + i, b: spans + 2 + i });
        // Verticals
        for (let i = 0; i <= spans; i++) members.push({ a: i, b: spans + 1 + i });
        // Diagonals (Pratt pattern)
        for (let i = 0; i < spans; i++) {
            if (i < spans / 2) members.push({ a: i, b: spans + 2 + i });
            else members.push({ a: i + 1, b: spans + 1 + i });
        }
        supports.push({ nodeId: 0, type: 'pin' });
        supports.push({ nodeId: spans, type: 'roller' });
        loads.push({ nodeId: Math.floor(spans / 2), fy: -50000, fx: 0 });
    } else if (name === 'warren') {
        const spans = 6;
        const h = 2;
        const w = 1.5;
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: 0 });
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: h });
        for (let i = 0; i < spans; i++) members.push({ a: i, b: i + 1 });
        for (let i = 0; i < spans; i++) members.push({ a: spans + 1 + i, b: spans + 2 + i });
        // Warren diagonals (alternating)
        for (let i = 0; i < spans; i++) {
            if (i % 2 === 0) members.push({ a: i, b: spans + 2 + i });
            else members.push({ a: i + 1, b: spans + 1 + i });
        }
        supports.push({ nodeId: 0, type: 'pin' });
        supports.push({ nodeId: spans, type: 'roller' });
        loads.push({ nodeId: Math.floor(spans / 2), fy: -50000, fx: 0 });
    } else if (name === 'howe') {
        const spans = 6;
        const h = 2;
        const w = 1.5;
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: 0 });
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: h });
        for (let i = 0; i < spans; i++) members.push({ a: i, b: i + 1 });
        for (let i = 0; i < spans; i++) members.push({ a: spans + 1 + i, b: spans + 2 + i });
        for (let i = 0; i <= spans; i++) members.push({ a: i, b: spans + 1 + i });
        // Howe diagonals (opposite of Pratt)
        for (let i = 0; i < spans; i++) {
            if (i < spans / 2) members.push({ a: i + 1, b: spans + 1 + i });
            else members.push({ a: i, b: spans + 2 + i });
        }
        supports.push({ nodeId: 0, type: 'pin' });
        supports.push({ nodeId: spans, type: 'roller' });
        loads.push({ nodeId: Math.floor(spans / 2), fy: -50000, fx: 0 });
    } else if (name === 'ktruss') {
        // K truss
        const spans = 4;
        const h = 2.5;
        const w = 2;
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: 0 });
        for (let i = 0; i <= spans; i++) nodes.push({ x: i * w - spans * w / 2, y: h });
        // Mid-height nodes
        for (let i = 0; i < spans; i++) nodes.push({ x: (i + 0.5) * w - spans * w / 2, y: h / 2 });
        const midStart = (spans + 1) * 2;
        for (let i = 0; i < spans; i++) members.push({ a: i, b: i + 1 });
        for (let i = 0; i < spans; i++) members.push({ a: spans + 1 + i, b: spans + 2 + i });
        for (let i = 0; i <= spans; i++) members.push({ a: i, b: spans + 1 + i });
        // K diagonals
        for (let i = 0; i < spans; i++) {
            members.push({ a: i, b: midStart + i });
            members.push({ a: midStart + i, b: spans + 2 + i });
        }
        supports.push({ nodeId: 0, type: 'pin' });
        supports.push({ nodeId: spans, type: 'roller' });
        loads.push({ nodeId: Math.floor(spans / 2), fy: -50000, fx: 0 });
    }

    rebuildVisuals();
    updateStatus('Template loaded — click ⚡ Analyze');
}

function clearAll() {
    nodes = []; members = []; supports = []; loads = [];
    result = null;
    while (deformedGroup.children.length) {
        const c = deformedGroup.children[0];
        deformedGroup.remove(c);
        if (c.geometry) c.geometry.dispose();
        if (c.material) c.material.dispose();
    }
    rebuildVisuals();
    $('truss-maxforce-readout').textContent = '—';
    $('truss-maxdisp-readout').textContent = '—';
    updateStatus('Ready — place nodes to begin');
}

// ═══════════════════════════════════════════════════════════════
// Pointer Handlers
// ═══════════════════════════════════════════════════════════════

function handlePointerDown(e) {
    if (e.button !== 0) return;
    const world = getWorldPos(e);
    if (!world) return;

    const snapped = snapToGrid(world.x, world.y);
    const nearIdx = findNodeNear(snapped.x, snapped.y);

    const loadFx = parseInt($('truss-load-fx').value) * 1000;
    const loadFy = parseInt($('truss-load-fy').value) * 1000;

    if (currentTool === 'node') {
        if (nearIdx === -1) {
            nodes.push({ x: snapped.x, y: snapped.y });
            rebuildVisuals();
        }
    } else if (currentTool === 'member') {
        if (nearIdx >= 0) {
            if (memberStart === null) {
                memberStart = nearIdx;
                if (nodeMeshes[nearIdx]) nodeMeshes[nearIdx].material.emissive.setHex(0x334466);
            } else if (nearIdx !== memberStart) {
                // Check if member already exists
                const exists = members.some(m =>
                    (m.a === memberStart && m.b === nearIdx) ||
                    (m.a === nearIdx && m.b === memberStart)
                );
                if (!exists) {
                    members.push({ a: memberStart, b: nearIdx });
                }
                memberStart = null;
                rebuildVisuals();
            }
        }
    } else if (currentTool === 'support') {
        if (nearIdx >= 0) {
            const type = document.querySelector('input[name="truss-support-type"]:checked').value;
            // Remove existing support on this node
            supports = supports.filter(s => s.nodeId !== nearIdx);
            supports.push({ nodeId: nearIdx, type });
            rebuildVisuals();
        }
    } else if (currentTool === 'load') {
        if (nearIdx >= 0) {
            // Remove existing load on this node
            loads = loads.filter(l => l.nodeId !== nearIdx);
            if (Math.abs(loadFx) > 0 || Math.abs(loadFy) > 0) {
                loads.push({ nodeId: nearIdx, fx: loadFx, fy: loadFy });
            }
            rebuildVisuals();
        }
    } else if (currentTool === 'delete') {
        if (nearIdx >= 0) {
            // Delete node and connected members
            members = members.filter(m => m.a !== nearIdx && m.b !== nearIdx);
            supports = supports.filter(s => s.nodeId !== nearIdx);
            loads = loads.filter(l => l.nodeId !== nearIdx);
            nodes.splice(nearIdx, 1);
            // Remap indices
            members = members.map(m => ({
                a: m.a > nearIdx ? m.a - 1 : m.a,
                b: m.b > nearIdx ? m.b - 1 : m.b,
            }));
            supports = supports.map(s => ({
                ...s,
                nodeId: s.nodeId > nearIdx ? s.nodeId - 1 : s.nodeId,
            }));
            loads = loads.map(l => ({
                ...l,
                nodeId: l.nodeId > nearIdx ? l.nodeId - 1 : l.nodeId,
            }));
            rebuildVisuals();
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    // Tool grid
    document.querySelectorAll('#truss-controls .tool-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('#truss-controls .tool-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentTool = btn.dataset.tool;
            memberStart = null;

            // Show/hide sub-options
            $('truss-support-options').classList.toggle('hidden', currentTool !== 'support');
            $('truss-load-options').classList.toggle('hidden', currentTool !== 'load');
        });
    });

    // Load sliders
    $('truss-load-fx').addEventListener('input', e => {
        $('truss-load-fx-val').textContent = parseInt(e.target.value) + ' kN';
    });
    $('truss-load-fy').addEventListener('input', e => {
        $('truss-load-fy-val').textContent = parseInt(e.target.value) + ' kN';
    });

    // Templates
    document.querySelectorAll('#truss-controls .template-btn').forEach(btn => {
        btn.addEventListener('click', () => loadTemplate(btn.dataset.template));
    });

    // Deform scale
    $('truss-deform-scale').addEventListener('input', e => {
        deformScale = parseInt(e.target.value);
        $('truss-deform-scale-val').textContent = deformScale + 'x';
        if (result && !result.error) showDeformed();
    });

    // Analyze / Clear
    $('truss-analyze-btn').addEventListener('click', analyze);
    $('truss-clear-btn').addEventListener('click', clearAll);

    // Pointer events
    renderer.domElement.addEventListener('pointerdown', e => {
        if (group.visible) handlePointerDown(e);
    });
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

function createGrid() {
    const gridGeo = new THREE.PlaneGeometry(20, 20);
    const gridMat = new THREE.MeshBasicMaterial({
        color: 0x111822,
        transparent: true,
        opacity: 0.3,
        side: THREE.DoubleSide,
    });
    gridMesh = new THREE.Mesh(gridGeo, gridMat);
    gridMesh.position.z = -0.1;
    group.add(gridMesh);

    // Grid lines
    const lineMat = new THREE.LineBasicMaterial({ color: 0x1a2030, transparent: true, opacity: 0.5 });
    for (let i = -10; i <= 10; i += 0.5) {
        const pts = [new THREE.Vector3(i, -10, -0.05), new THREE.Vector3(i, 10, -0.05)];
        const geo = new THREE.BufferGeometry().setFromPoints(pts);
        group.add(new THREE.Line(geo, lineMat));

        const pts2 = [new THREE.Vector3(-10, i, -0.05), new THREE.Vector3(10, i, -0.05)];
        const geo2 = new THREE.BufferGeometry().setFromPoints(pts2);
        group.add(new THREE.Line(geo2, lineMat));
    }
}

export function initTrussModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    supportMeshGroup = new THREE.Group();
    group.add(supportMeshGroup);

    loadMeshGroup = new THREE.Group();
    group.add(loadMeshGroup);

    deformedGroup = new THREE.Group();
    group.add(deformedGroup);

    createGrid();
    bindUI();

    registerModule('truss', {
        activate() {
            group.visible = true;
            // Set camera for 2D view
            camera.position.set(0, 2, 12);
            orbitControls.target.set(0, 1.5, 0);
        },
        deactivate() {
            group.visible = false;
            // Reset camera
            camera.position.set(5, 4, 6);
            orbitControls.target.set(0, 0.5, 0);
        },
        update(dt, elapsed) {
            // nothing continuous needed
        },
    });
}
