// ═══════════════════════════════════════════════════════════════
// beam.js — Beam Analysis Module
// Euler-Bernoulli & Timoshenko beam theory with real-time deformation
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, camera, registerModule, MATERIALS, clamp, heatmapColor, formatSI, getCachedMaterial, disposeObject } from './app.js';

const $ = id => document.getElementById(id);
const BEAM_SEGS_X = 120;
const BEAM_SEGS_Y = 6;
const BEAM_SEGS_Z = 6;

let group;
let beamMesh, beamGeometry, beamMaterial, originalPositions;
let momentRibbonMesh, shearRibbonMesh;
let supportMeshes = [];
let loadArrow, distLoadArrows = [];
let dirty = true;

// ── State ──
const state = {
    material: 'steel',
    supportType: 'simply-supported',
    theory: 'euler',    // 'euler' or 'timoshenko'
    length: 4.0,        // m
    width: 0.1,         // m
    height: 0.2,        // m
    pointLoad: 50000,   // N
    loadPos: 0.5,       // fraction 0-1
    distLoad: 0,        // N/m
    selfWeight: false,
    deformScale: 50,
    showMoment: true,
    showShear: true,
    showStress: true,
};

function getI() {
    return (state.width * Math.pow(state.height, 3)) / 12;
}

function getE() {
    return MATERIALS[state.material].E;
}

function getG() {
    return MATERIALS[state.material].G;
}

function getArea() {
    return state.width * state.height;
}

// Timoshenko shear correction factor for rectangular cross-section
const KAPPA = 5 / 6;

// Self-weight distributed load (N/m)
function getSelfWeightLoad() {
    if (!state.selfWeight) return 0;
    const mat = MATERIALS[state.material];
    return mat.density * getArea() * 9.81; // ρ * A * g
}

// ═══════════════════════════════════════════════════════════════
// Beam Deflection Calculations
// ═══════════════════════════════════════════════════════════════

// Returns { deflection, moment, shear } at position x (0 to L)
function calcBeam(x) {
    const L = state.length;
    const P = state.pointLoad;
    const a = state.loadPos * L;
    const b = L - a;
    const w = state.distLoad + getSelfWeightLoad();
    const EI = getE() * getI();

    let defl = 0, M = 0, V = 0;

    if (state.supportType === 'simply-supported') {
        if (P !== 0) {
            const Ra = P * b / L;
            if (x <= a) {
                M = Ra * x;
                V = Ra;
                defl = -(P * b * x) / (6 * EI * L) * (L * L - b * b - x * x);
            } else {
                M = Ra * x - P * (x - a);
                V = Ra - P;
                defl = -(P * a * (L - x)) / (6 * EI * L) * (2 * L * x - a * a - x * x);
            }
        }
        if (w !== 0) {
            M += w * x * (L - x) / 2;
            V += w * (L / 2 - x);
            defl += -(w * x) / (24 * EI) * (L * L * L - 2 * L * x * x + x * x * x);
        }
    } else if (state.supportType === 'cantilever') {
        if (P !== 0) {
            if (x <= a) {
                M = -P * (a - x);
                V = P;
                defl = -(P * x * x) / (6 * EI) * (3 * a - x);
            } else {
                M = 0;
                V = 0;
                defl = -(P * a * a) / (6 * EI) * (3 * x - a);
            }
        }
        if (w !== 0) {
            M += -w * (L - x) * (L - x) / 2;
            V += w * (L - x);
            defl += -(w * x * x) / (24 * EI) * (6 * L * L - 4 * L * x + x * x);
        }
    } else if (state.supportType === 'fixed-fixed') {
        if (P !== 0) {
            const a2 = a, b2 = b;
            const Ma = -P * a2 * b2 * b2 / (L * L);
            const Ra = P * b2 * b2 * (3 * a2 + b2) / (L * L * L);
            if (x <= a2) {
                M = Ra * x + Ma;
                V = Ra;
            } else {
                M = Ra * x + Ma - P * (x - a2);
                V = Ra - P;
            }
            if (x <= a2) {
                defl = -(P * b2 * b2 * x * x) / (6 * EI * L * L * L) * (3 * a2 * L - x * (3 * a2 + b2));
            } else {
                defl = -(P * a2 * a2 * (L - x) * (L - x)) / (6 * EI * L * L * L) * (3 * b2 * L - (L - x) * (3 * b2 + a2));
            }
        }
        if (w !== 0) {
            M += w * L * L / 12 - w * L * x / 2 + w * x * x / 2;
            V += w * L / 2 - w * x;
            defl += -(w * x * x) / (24 * EI) * Math.pow(L - x, 2);
        }
    } else if (state.supportType === 'overhanging') {
        // Overhanging beam: pin at x=0, roller at x=Ls, overhang to x=L
        const Ls = 0.7 * L;
        if (P !== 0) {
            if (a <= Ls) {
                // Load on the span
                const Ra = P * (Ls - a) / Ls;
                const Rb = P * a / Ls;
                if (x <= a) {
                    M = Ra * x;
                    V = Ra;
                    // Simply-supported deflection on span
                    const bSpan = Ls - a;
                    defl = -(P * bSpan * x) / (6 * EI * Ls) * (Ls * Ls - bSpan * bSpan - x * x);
                } else if (x <= Ls) {
                    M = Ra * x - P * (x - a);
                    V = Ra - P;
                    const bSpan = Ls - a;
                    defl = -(P * a * (Ls - x)) / (6 * EI * Ls) * (2 * Ls * x - a * a - x * x);
                } else {
                    // Overhang: no load here, zero moment
                    M = 0;
                    V = 0;
                    // Slope at roller (x = Ls) from span deflection curve
                    const bSpan = Ls - a;
                    const slopeAtRoller = -(P * a) / (6 * EI * Ls) * (2 * Ls * Ls - a * a - 3 * Ls * Ls + a * a + Ls * Ls);
                    // Simpler: θ_B = P*a*(2*Ls² - a²) / (6*EI*Ls) — but we need sign
                    const thetaB = (P * a * (2 * Ls * Ls - a * a)) / (6 * EI * Ls);
                    defl = -thetaB * (x - Ls);
                }
            } else {
                // Load on the overhang (a > Ls)
                // Reactions: ΣM about A: Rb*Ls = P*a, so Rb = P*a/Ls
                // ΣFy: Ra + Rb = P, so Ra = P - P*a/Ls = P*(Ls - a)/Ls (negative since a > Ls)
                const Rb = P * a / Ls;
                const Ra = P - Rb;  // negative
                if (x <= Ls) {
                    M = Ra * x;
                    V = Ra;
                    // Span deflects under end moment Mb = -P*(a - Ls) at roller
                    const Mb = -P * (a - Ls);  // moment at B from overhang load
                    // Deflection from moment at end of simply-supported span:
                    // δ = Mb * x * (Ls² - x²) / (6 * EI * Ls)
                    defl = Mb * x * (Ls * Ls - x * x) / (6 * EI * Ls);
                } else if (x <= a) {
                    M = Ra * x + Rb * (x - Ls);
                    V = Ra + Rb;
                    // Overhang cantilever from roller support
                    const xo = x - Ls;
                    const ao = a - Ls;
                    const Mb = -P * (a - Ls);
                    const thetaB = Mb * Ls / (3 * EI);  // slope at B from span
                    defl = thetaB * xo + (Ra * xo * xo * xo) / (6 * EI) + Rb * 0;  // use moment area
                    // More accurate: treat overhang with cantilever formula
                    defl = -(P * xo * xo) / (6 * EI) * (3 * ao - xo) + thetaB * xo;
                } else {
                    M = Ra * x + Rb * (x - Ls) - P * (x - a);
                    V = Ra + Rb - P;  // = 0
                    const xo = x - Ls;
                    const ao = a - Ls;
                    const Mb = -P * (a - Ls);
                    const thetaB = Mb * Ls / (3 * EI);
                    defl = -(P * ao * ao) / (6 * EI) * (3 * xo - ao) + thetaB * xo;
                }
            }
        }
        // Distributed load on span portion only
        if (w !== 0) {
            if (x <= Ls) {
                M += w * x * (Ls - x) / 2;
                V += w * (Ls / 2 - x);
                defl += -(w * x) / (24 * EI) * (Ls * Ls * Ls - 2 * Ls * x * x + x * x * x);
            } else {
                // Overhang: slope continuation from span end
                const thetaB_w = (w * Ls * Ls * Ls) / (24 * EI);
                defl += -thetaB_w * (x - Ls);
                // No distributed load on overhang, M and V from span reactions carry through
                V += 0;
                M += 0;
            }
        }
    }

    // Timoshenko correction — add shear deformation (closed-form per support type)
    if (state.theory === 'timoshenko') {
        const GA = getG() * getArea() * KAPPA;
        if (GA > 0) {
            let shearDefl = 0;
            if (state.supportType === 'simply-supported') {
                // Point load: δ_s = P·a·b / (κGA·L) scaled by position
                if (P !== 0) {
                    if (x <= a) {
                        shearDefl += P * b / (GA * L) * x;
                    } else {
                        shearDefl += P * a / (GA * L) * (L - x);
                    }
                }
                // UDL: δ_s = w·x·(L-x) / (2·κGA)
                if (w !== 0) {
                    shearDefl += w * x * (L - x) / (2 * GA);
                }
            } else if (state.supportType === 'cantilever') {
                // Point load: δ_s = P/(κGA) for x ≤ a, P*a/(κGA*x) doesn't apply — constant
                if (P !== 0) {
                    if (x <= a) {
                        shearDefl += P / GA * (x <= a ? 1 : 0) * Math.min(x, a) / a * (a > 0 ? 1 : 0);
                        // Simpler: uniform shear region
                        shearDefl = P * x / (GA * a) * Math.min(x, a);
                        // Correct: δ_s(x) = V(x) integrated = P·x/(κGA) for x<=a
                        shearDefl = (x <= a) ? P * x / GA : P * a / GA;
                    } else {
                        shearDefl += P * a / GA;
                    }
                }
                // UDL: δ_s = w·(L·x - x²/2) / (κGA)
                if (w !== 0) {
                    shearDefl += w * (L * x - x * x / 2) / GA;
                }
            } else if (state.supportType === 'fixed-fixed') {
                // UDL: δ_s = w·x·(L-x) / (2·κGA)
                if (w !== 0) {
                    shearDefl += w * x * (L - x) / (2 * GA);
                }
                // Point load: piecewise
                if (P !== 0) {
                    const Rb = P * a * a * (3 * b + a) / (L * L * L);
                    const Ra = P - Rb;
                    if (x <= a) {
                        shearDefl += Ra * x / GA;
                    } else {
                        shearDefl += (Ra * a + (Ra - P) * (x - a)) / GA;
                    }
                    // Clamp to positive
                    shearDefl = Math.abs(shearDefl);
                }
            }
            defl += -shearDefl;
        }
    }

    return { deflection: defl, moment: M, shear: V };
}


// ═══════════════════════════════════════════════════════════════
// 2D Chart Rendering (SFD & BMD)
// ═══════════════════════════════════════════════════════════════
function drawCharts() {
    drawChart('canvas-sfd', 'shear', '#EF4444');
    drawChart('canvas-bmd', 'moment', '#2563EB');
}

function drawChart(canvasId, valueKey, color) {
    const canvas = $(canvasId);
    if (!canvas) return;

    // Resize calc
    const rect = canvas.parentElement.getBoundingClientRect();
    canvas.width = rect.width * window.devicePixelRatio;
    canvas.height = rect.height * window.devicePixelRatio;

    const ctx = canvas.getContext('2d');
    ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
    ctx.clearRect(0, 0, rect.width, rect.height);

    const w = rect.width;
    const h = rect.height;

    // Data generation
    const L = state.length;
    const points = [];
    const steps = 100;

    let maxVal = 0;

    for (let i = 0; i <= steps; i++) {
        const x = (i / steps) * L;
        const r = calcBeam(x);
        const val = r[valueKey];
        points.push(val);
        if (Math.abs(val) > maxVal) maxVal = Math.abs(val);
    }

    if (maxVal === 0) maxVal = 1; // avoid div/0

    // Drawing
    ctx.beginPath();
    ctx.lineWidth = 2;
    ctx.strokeStyle = color;
    ctx.moveTo(0, h / 2);

    // Fill area
    ctx.fillStyle = color + '20'; // transparent hex

    // Draw path
    for (let i = 0; i <= steps; i++) {
        const px = (i / steps) * w;
        // Normalize val to -1..1 then map to height. 
        // Note: Graph convention usually + up, canvas + down.
        // Also structural engineering diagrams conventions vary (Moments plotted on tension side etc).
        // Here we just map positive value to 'up' (-y in canvas)
        const py = (h / 2) - (points[i] / maxVal) * (h / 2 * 0.8);
        ctx.lineTo(px, py);
    }

    // Close path for fill
    ctx.lineTo(w, h / 2);
    ctx.lineTo(0, h / 2);
    ctx.fill();

    // Stroke path again
    ctx.beginPath();
    ctx.moveTo(0, h / 2 - (points[0] / maxVal) * (h / 2 * 0.8));
    for (let i = 1; i <= steps; i++) {
        const px = (i / steps) * w;
        const py = h / 2 - (points[i] / maxVal) * (h / 2 * 0.8);
        ctx.lineTo(px, py);
    }
    ctx.stroke();

    // Zero line
    ctx.beginPath();
    ctx.strokeStyle = '#CBD5E1'; // light grey
    ctx.setLineDash([4, 4]);
    ctx.lineWidth = 1;
    ctx.moveTo(0, h / 2);
    ctx.lineTo(w, h / 2);
    ctx.stroke();
    ctx.setLineDash([]);
}

// ═══════════════════════════════════════════════════════════════
// 3D Objects
// ═══════════════════════════════════════════════════════════════

function createBeam() {
    if (beamMesh) {
        group.remove(beamMesh);
        beamGeometry.dispose();
        beamMaterial.dispose();
    }

    const mat = MATERIALS[state.material];
    beamGeometry = new THREE.BoxGeometry(state.length, state.height, state.width, BEAM_SEGS_X, BEAM_SEGS_Y, BEAM_SEGS_Z);
    beamMaterial = new THREE.MeshStandardMaterial({
        color: mat.color,
        roughness: 0.35,
        metalness: 0.65,
        vertexColors: state.showStress,
    });
    beamMesh = new THREE.Mesh(beamGeometry, beamMaterial);
    beamMesh.position.set(state.length / 2, state.height / 2 + 0.3, 0);
    beamMesh.castShadow = true;
    beamMesh.receiveShadow = true;
    group.add(beamMesh);

    originalPositions = beamGeometry.attributes.position.array.slice();
    dirty = true;
}

function createSupports() {
    supportMeshes.forEach(m => { group.remove(m); m.geometry.dispose(); m.material.dispose(); });
    supportMeshes = [];

    const L = state.length;

    function makeTriangle(x, color) {
        const shape = new THREE.Shape();
        shape.moveTo(-0.15, 0);
        shape.lineTo(0.15, 0);
        shape.lineTo(0, 0.25);
        shape.closePath();
        const geo = new THREE.ExtrudeGeometry(shape, { depth: 0.12, bevelEnabled: false });
        const mat = getCachedMaterial(color, { roughness: 0.5, metalness: 0.3 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(x, 0, -0.06);
        mesh.castShadow = true;
        group.add(mesh);
        supportMeshes.push(mesh);
    }

    function makeWall(x) {
        const geo = new THREE.BoxGeometry(0.15, 0.8, 0.5);
        const mat = getCachedMaterial(0x444444, { roughness: 0.7, metalness: 0.2 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(x - 0.075, 0.4, 0);
        mesh.castShadow = true;
        group.add(mesh);
        supportMeshes.push(mesh);

        for (let i = 0; i < 5; i++) {
            const lineGeo = new THREE.BoxGeometry(0.01, 0.12, 0.5);
            const lineMat = new THREE.MeshBasicMaterial({ color: 0x666666 });
            const lineMesh = new THREE.Mesh(lineGeo, lineMat);
            lineMesh.position.set(x - 0.075, 0.15 + i * 0.15, 0);
            lineMesh.rotation.z = Math.PI / 4;
            group.add(lineMesh);
            supportMeshes.push(lineMesh);
        }
    }

    function makeRoller(x, color) {
        const geo = new THREE.CylinderGeometry(0.08, 0.08, 0.15, 16);
        const mat = getCachedMaterial(color, { roughness: 0.4, metalness: 0.5 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.rotation.x = Math.PI / 2;
        mesh.position.set(x, 0.08, 0);
        mesh.castShadow = true;
        group.add(mesh);
        supportMeshes.push(mesh);
    }

    if (state.supportType === 'simply-supported') {
        makeTriangle(0, 0x3fb950);
        makeTriangle(L, 0x3fb950);
        makeRoller(L, 0x3fb950);
    } else if (state.supportType === 'cantilever') {
        makeWall(0);
    } else if (state.supportType === 'fixed-fixed') {
        makeWall(0);
        makeWall(L + 0.15);
    } else if (state.supportType === 'overhanging') {
        makeTriangle(0, 0x3fb950);
        makeTriangle(0.7 * L, 0xd29922);
    }
}

function createLoadArrow() {
    if (loadArrow) { disposeObject(loadArrow); loadArrow = null; }
    distLoadArrows.forEach(a => disposeObject(a));
    distLoadArrows = [];

    const L = state.length;
    const P = state.pointLoad;
    const a = state.loadPos * L;

    if (P !== 0) {
        const dir = new THREE.Vector3(0, P > 0 ? -1 : 1, 0);
        const origin = new THREE.Vector3(a, state.height + 0.3 + Math.abs(P) / 50000 * 0.8 + 0.5, 0);
        const arrowLen = Math.abs(P) / 50000 * 0.8 + 0.2;
        const color = P > 0 ? 0xf85149 : 0x58a6ff;
        loadArrow = new THREE.ArrowHelper(dir, origin, arrowLen, color, 0.12, 0.08);
        group.add(loadArrow);
    }

    const totalDist = state.distLoad + getSelfWeightLoad();
    if (totalDist !== 0) {
        const nArrows = 12;
        for (let i = 0; i <= nArrows; i++) {
            const x = (i / nArrows) * L;
            const mag = Math.abs(totalDist) / 30000 * 0.4 + 0.15;
            const dir = new THREE.Vector3(0, totalDist > 0 ? -1 : 1, 0);
            const origin = new THREE.Vector3(x, state.height + 0.3 + mag + 0.3, 0);
            const color = totalDist > 0 ? 0xf85149 : 0x58a6ff;
            const arrow = new THREE.ArrowHelper(dir, origin, mag, color, 0.06, 0.04);
            group.add(arrow);
            distLoadArrows.push(arrow);
        }
    }
}

function createDiagramRibbons() {
    if (momentRibbonMesh) { group.remove(momentRibbonMesh); momentRibbonMesh.geometry.dispose(); momentRibbonMesh.material.dispose(); }
    if (shearRibbonMesh) { group.remove(shearRibbonMesh); shearRibbonMesh.geometry.dispose(); shearRibbonMesh.material.dispose(); }

    const L = state.length;
    const nPts = 100;

    let maxM = 0, maxV = 0;
    for (let i = 0; i <= nPts; i++) {
        const x = (i / nPts) * L;
        const r = calcBeam(x);
        maxM = Math.max(maxM, Math.abs(r.moment));
        maxV = Math.max(maxV, Math.abs(r.shear));
    }

    if (state.showMoment && maxM > 0) {
        const pts = [];
        for (let i = 0; i <= nPts; i++) {
            const x = (i / nPts) * L;
            const r = calcBeam(x);
            pts.push(new THREE.Vector3(x, -r.moment / maxM * 0.8 - 0.5, 0.35));
        }
        const baselinePts = [];
        for (let i = nPts; i >= 0; i--) {
            baselinePts.push(new THREE.Vector3((i / nPts) * L, -0.5, 0.35));
        }
        const allPts = [...pts, ...baselinePts];

        const shape = new THREE.Shape();
        shape.moveTo(allPts[0].x, allPts[0].y);
        for (let i = 1; i < allPts.length; i++) {
            shape.lineTo(allPts[i].x, allPts[i].y);
        }
        shape.closePath();

        const geo = new THREE.ShapeGeometry(shape);
        const mat = new THREE.MeshBasicMaterial({
            color: 0xa371f7,
            transparent: true,
            opacity: 0.4,
            side: THREE.DoubleSide,
        });
        momentRibbonMesh = new THREE.Mesh(geo, mat);
        momentRibbonMesh.position.set(0, 0, 0);
        group.add(momentRibbonMesh);
    }

    if (state.showShear && maxV > 0) {
        const pts = [];
        for (let i = 0; i <= nPts; i++) {
            const x = (i / nPts) * L;
            const r = calcBeam(x);
            pts.push(new THREE.Vector3(x, r.shear / maxV * 0.6 - 1.5, -0.35));
        }
        const baselinePts = [];
        for (let i = nPts; i >= 0; i--) {
            baselinePts.push(new THREE.Vector3((i / nPts) * L, -1.5, -0.35));
        }
        const allPts = [...pts, ...baselinePts];

        const shape = new THREE.Shape();
        shape.moveTo(allPts[0].x, allPts[0].y);
        for (let i = 1; i < allPts.length; i++) {
            shape.lineTo(allPts[i].x, allPts[i].y);
        }
        shape.closePath();

        const geo = new THREE.ShapeGeometry(shape);
        const mat = new THREE.MeshBasicMaterial({
            color: 0x58a6ff,
            transparent: true,
            opacity: 0.4,
            side: THREE.DoubleSide,
        });
        shearRibbonMesh = new THREE.Mesh(geo, mat);
        group.add(shearRibbonMesh);
    }
}

// ═══════════════════════════════════════════════════════════════
// Deformation & Stress Coloring
// ═══════════════════════════════════════════════════════════════

function deformBeam() {
    if (!beamMesh || !dirty) return;
    dirty = false;

    const pos = beamGeometry.attributes.position;
    const L = state.length;
    const halfL = L / 2;
    const halfH = state.height / 2;
    const scale = state.deformScale;

    let maxDefl = 0;
    for (let i = 0; i < 20; i++) {
        const x = (i / 19) * L;
        const r = calcBeam(x);
        maxDefl = Math.max(maxDefl, Math.abs(r.deflection));
    }

    let colors;
    if (state.showStress) {
        colors = new Float32Array(pos.count * 3);
    }

    for (let i = 0; i < pos.count; i++) {
        const ox = originalPositions[i * 3];
        const oy = originalPositions[i * 3 + 1];
        const oz = originalPositions[i * 3 + 2];

        const xBeam = ox + halfL;
        const yLocal = oy;

        const xClamped = clamp(xBeam, 0, L);
        const r = calcBeam(xClamped);

        const defl = r.deflection * scale;
        pos.array[i * 3] = ox;
        pos.array[i * 3 + 1] = oy + defl;
        pos.array[i * 3 + 2] = oz;

        if (state.showStress && colors) {
            const sigma = Math.abs(r.moment) > 0 ? -r.moment * yLocal / getI() : 0;
            const maxSigma = MATERIALS[state.material].yieldStress;
            const t = clamp(Math.abs(sigma) / maxSigma, 0, 1);
            const c = heatmapColor(t);
            colors[i * 3] = c.r;
            colors[i * 3 + 1] = c.g;
            colors[i * 3 + 2] = c.b;
        }
    }

    pos.needsUpdate = true;

    if (state.showStress && colors) {
        beamGeometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
        beamMaterial.vertexColors = true;
        beamMaterial.needsUpdate = true;
    } else {
        beamMaterial.vertexColors = false;
        beamMaterial.needsUpdate = true;
    }

    beamGeometry.computeVertexNormals();
    updateReadouts();
}

function updateReadouts() {
    const L = state.length;
    const I = getI();

    let maxDefl = 0, maxM = 0, maxV = 0;
    const steps = 100;
    for (let i = 0; i <= steps; i++) {
        const x = (i / steps) * L;
        const r = calcBeam(x);
        if (Math.abs(r.deflection) > Math.abs(maxDefl)) maxDefl = r.deflection;
        if (Math.abs(r.moment) > Math.abs(maxM)) maxM = r.moment;
        if (Math.abs(r.shear) > Math.abs(maxV)) maxV = r.shear;
    }

    const maxSigma = Math.abs(maxM) * (state.height / 2) / I;
    // Reaction force roughly approximated by max shear at supports + applied loads (simplified)
    const reaction = Math.abs(maxV);

    const safetyFactor = maxSigma > 0 ? MATERIALS[state.material].yieldStress / maxSigma : 999;

    // KPI Cards
    const kpiStress = $('kpi-stress');
    if (kpiStress) kpiStress.textContent = (maxSigma / 1e6).toFixed(1);

    const kpiSafety = $('kpi-safety');
    if (kpiSafety) {
        kpiSafety.textContent = safetyFactor > 99 ? '>99' : safetyFactor.toFixed(2);
        // Find badge
        const badge = kpiSafety.parentElement.nextElementSibling;
        if (badge) {
            if (safetyFactor >= 2) {
                badge.className = 'kpi-badge success';
                badge.textContent = '✓ Pass';
            } else if (safetyFactor >= 1) {
                badge.className = 'kpi-badge info';
                badge.textContent = '⚠️ Marginal';
            } else {
                badge.className = 'kpi-badge';
                badge.style.background = '#FEE2E2';
                badge.style.color = '#EF4444';
                badge.textContent = '⛔ Fail';
            }
        }
    }

    const kpiDeflection = $('kpi-deflection');
    if (kpiDeflection) kpiDeflection.textContent = (maxDefl * 1000).toFixed(1);

    const kpiReaction = $('kpi-reaction');
    if (kpiReaction) kpiReaction.textContent = (reaction / 1000).toFixed(1);

    // Draw charts whenever calculations update
    drawCharts();
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    function markDirty() { dirty = true; }
    function updateCharts() { drawCharts(); }

    // Helper to sync range and number inputs
    function syncInputs(rangeId, numId, scale = 1) {
        const range = $(rangeId);
        const num = $(numId);
        if (!range || !num) return;

        range.addEventListener('input', () => {
            num.value = range.value * scale;
            num.dispatchEvent(new Event('input'));
        });

        num.addEventListener('input', () => {
            range.value = num.value / scale;
            // Trigger downstream logic attached to range if any, or just update state manually in specific handlers
        });
    }

    $('beam-material').addEventListener('change', e => {
        state.material = e.target.value;
        const mat = MATERIALS[state.material];
        if (mat) {
            const eVal = $('mat-e');
            if (eVal) eVal.value = mat.E / 1e9;
            const nuVal = $('mat-nu');
            if (nuVal) nuVal.value = mat.nu;
        }
        createBeam(); createSupports(); createLoadArrow(); createDiagramRibbons(); updateCharts();
    });

    // Initialize readonly material inputs
    const initMat = MATERIALS[state.material];
    if (initMat) {
        if ($('mat-e')) $('mat-e').value = initMat.E / 1e9;
        if ($('mat-nu')) $('mat-nu').value = initMat.nu;
    }

    $('beam-length').addEventListener('input', e => {
        state.length = parseFloat(e.target.value);
        $('beam-length-val').textContent = state.length.toFixed(1) + 'm';
        createBeam(); createSupports(); createLoadArrow(); createDiagramRibbons(); updateCharts();
    });

    // Width: Input <-> State
    $('beam-width-input').addEventListener('input', e => {
        state.width = parseFloat(e.target.value) / 1000;
        createBeam(); markDirty(); updateReadouts();
    });

    // Height: Input <-> State
    $('beam-height-input').addEventListener('input', e => {
        state.height = parseFloat(e.target.value) / 1000;
        createBeam(); createSupports(); createLoadArrow(); createDiagramRibbons(); updateCharts();
    });

    // Web/Flange (just visual for now if we strictly follow the rectangular logic, or we update I)
    // For this 1:1 replication of the "Rectangular Beam" logic, we might ignore them or just store them.
    // The user requirement says "Input fields for Web (t) and Flange (t)". 
    // If the beam is rectangular, these might be ready for I-beam implementation later.

    // Loads
    $('beam-point-load-input').addEventListener('input', e => {
        state.pointLoad = parseFloat(e.target.value) * 1000;
        createLoadArrow(); createDiagramRibbons(); markDirty(); updateCharts();
    });

    $('beam-load-pos-input').addEventListener('input', e => {
        state.loadPos = parseFloat(e.target.value) / state.length; // Approximate if strictly x position
        // If the input is absolute position X in meters:
        // state.loadPos is fraction 0-1 in the code currently
        state.loadPos = clamp(parseFloat(e.target.value) / state.length, 0, 1);

        createLoadArrow(); createDiagramRibbons(); markDirty(); updateCharts();
    });

    // Update load position input relative to length slider
    $('beam-length').addEventListener('input', () => {
        const posInput = $('beam-load-pos-input');
        if (posInput) posInput.value = (state.loadPos * state.length).toFixed(2);
    });

    $('beam-dist-load-input').addEventListener('input', e => {
        state.distLoad = parseFloat(e.target.value) * 1000;
        createLoadArrow(); createDiagramRibbons(); markDirty(); updateCharts();
    });

    // Run Analysis Button (Re-trigger calc/vis)
    const runBtn = $('btn-run-analysis');
    if (runBtn) {
        runBtn.addEventListener('click', () => {
            createBeam(); createSupports(); createLoadArrow(); createDiagramRibbons(); updateCharts();
            // Simulate log
            const logBody = document.querySelector('.log-body');
            if (logBody) {
                const time = new Date().toLocaleTimeString('en-US', { hour12: false });
                logBody.innerHTML += `<div class="log-line success"><span class="log-time">[${time}]</span> Analysis updated successfully.</div>`;
                logBody.scrollTop = logBody.scrollHeight;
            }
        });
    }

    // Initialize Charts
    window.addEventListener('resize', drawCharts);
    setTimeout(drawCharts, 500); // Initial draw
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initBeamModule() {
    group = new THREE.Group();
    scene.add(group);

    createBeam();
    createSupports();
    createLoadArrow();
    createDiagramRibbons();
    bindUI();

    registerModule('beam', {
        activate() {
            group.visible = true;
            dirty = true;
        },
        deactivate() {
            group.visible = false;
        },
        update(dt, elapsed) {
            deformBeam();
        },
    });
}
