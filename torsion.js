// ═══════════════════════════════════════════════════════════════
// torsion.js — Torsion Module
// Circular shaft analysis with power transmission & safety factor
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, registerModule, MATERIALS, clamp, heatmapColor, formatSI, getCachedMaterial } from './app.js';

const $ = id => document.getElementById(id);
let group;
let shaftMesh, shaftGeom, shaftMat, originalPositions;
let fixedWallMesh;
let torqueArrow;
let dirty = true;

const SHAFT_SEGS_RADIAL = 32;
const SHAFT_SEGS_HEIGHT = 80;

const state = {
    material: 'steel',
    length: 2.0,
    outerR: 0.05,
    innerR: 0.025,
    hollow: false,
    torque: 10000,  // N·m
    rpm: 0,         // shaft speed in RPM
    deformScale: 20,
};

function getG() { return MATERIALS[state.material].G; }

function getJ() {
    if (state.hollow) {
        return (Math.PI / 2) * (Math.pow(state.outerR, 4) - Math.pow(state.innerR, 4));
    }
    return (Math.PI / 2) * Math.pow(state.outerR, 4);
}

function calcTorsion() {
    const G = getG();
    const J = getJ();
    const T = state.torque;
    const L = state.length;
    const r = state.outerR;

    const tauMax = T * r / J;
    const phi = T * L / (G * J);

    // Power transmission: P = T * ω = T * (2π·n/60)
    const omega = state.rpm > 0 ? (2 * Math.PI * state.rpm) / 60 : 0;
    const power = Math.abs(T) * omega; // watts

    // Safety factor
    const yieldShear = MATERIALS[state.material].yieldStress * 0.577; // von Mises: τ_y = σ_y / √3
    const safetyFactor = Math.abs(tauMax) > 0 ? yieldShear / Math.abs(tauMax) : Infinity;

    return { tauMax, phi, J, G, power, safetyFactor };
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

    const mat = MATERIALS[state.material];
    const visualR = state.outerR * 10;
    const visualIR = state.hollow ? state.innerR * 10 : 0;

    if (state.hollow) {
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

    if (!state.hollow) {
        shaftMesh.rotation.z = -Math.PI / 2;
        shaftMesh.position.set(state.length / 2, 0.8, 0);
    } else {
        shaftMesh.rotation.z = -Math.PI / 2;
        shaftMesh.position.set(0, 0.8, 0);
    }

    shaftMesh.castShadow = true;
    group.add(shaftMesh);

    originalPositions = shaftGeom.attributes.position.array.slice();
    dirty = true;
}

function createWall() {
    if (fixedWallMesh) { group.remove(fixedWallMesh); fixedWallMesh.geometry.dispose(); fixedWallMesh.material.dispose(); }

    const geo = new THREE.BoxGeometry(0.12, 1.2, 1.2);
    const mat = getCachedMaterial(0x444444, { roughness: 0.7, metalness: 0.2 });
    fixedWallMesh = new THREE.Mesh(geo, mat);
    fixedWallMesh.position.set(-0.06, 0.8, 0);
    fixedWallMesh.castShadow = true;
    group.add(fixedWallMesh);
}

function createTorqueArrow() {
    if (torqueArrow) group.remove(torqueArrow);

    const T = state.torque;
    if (Math.abs(T) < 1) return;

    const torusGeo = new THREE.TorusGeometry(0.4, 0.03, 8, 32, Math.PI * 1.5);
    const color = T > 0 ? 0x3fb950 : 0xf85149;
    const torusMat = new THREE.MeshBasicMaterial({ color });
    torqueArrow = new THREE.Mesh(torusGeo, torusMat);
    torqueArrow.position.set(state.length + 0.2, 0.8, 0);
    torqueArrow.rotation.y = Math.PI / 2;
    group.add(torqueArrow);

    const coneGeo = new THREE.ConeGeometry(0.06, 0.15, 8);
    const coneMat = new THREE.MeshBasicMaterial({ color });
    const cone = new THREE.Mesh(coneGeo, coneMat);
    cone.position.set(0, 0.4, 0);
    cone.rotation.z = T > 0 ? -Math.PI / 2 : Math.PI / 2;
    torqueArrow.add(cone);
}

// ═══════════════════════════════════════════════════════════════
// Deformation & Stress Coloring
// ═══════════════════════════════════════════════════════════════

function deformShaft() {
    if (!shaftMesh || !dirty) return;
    dirty = false;

    const pos = shaftGeom.attributes.position;
    const { tauMax, phi } = calcTorsion();
    const L = state.length;
    const scale = state.deformScale;

    const colors = new Float32Array(pos.count * 3);

    for (let i = 0; i < pos.count; i++) {
        const ox = originalPositions[i * 3];
        const oy = originalPositions[i * 3 + 1];
        const oz = originalPositions[i * 3 + 2];

        let xAlongShaft, r, theta;

        if (!state.hollow) {
            xAlongShaft = oy;
            r = Math.sqrt(ox * ox + oz * oz);
            theta = Math.atan2(oz, ox);
        } else {
            xAlongShaft = oz;
            r = Math.sqrt(ox * ox + oy * oy);
            theta = Math.atan2(oy, ox);
        }

        const twistAngle = phi * (xAlongShaft / L + 0.5) * scale;
        const newTheta = theta + twistAngle;

        if (!state.hollow) {
            pos.array[i * 3] = r * Math.cos(newTheta);
            pos.array[i * 3 + 1] = oy;
            pos.array[i * 3 + 2] = r * Math.sin(newTheta);
        } else {
            pos.array[i * 3] = r * Math.cos(newTheta);
            pos.array[i * 3 + 1] = r * Math.sin(newTheta);
            pos.array[i * 3 + 2] = oz;
        }

        const visualR = state.outerR * 10;
        const rNorm = r / visualR;
        const tau = Math.abs(tauMax) * rNorm;
        // Use shear yield stress τ_y = σ_y / √3 (von Mises criterion)
        const yieldShear = MATERIALS[state.material].yieldStress * 0.5774;
        const t = clamp(tau / yieldShear, 0, 1);
        const c = heatmapColor(t);
        colors[i * 3] = c.r;
        colors[i * 3 + 1] = c.g;
        colors[i * 3 + 2] = c.b;
    }

    pos.needsUpdate = true;
    shaftGeom.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    shaftGeom.computeVertexNormals();

    updateReadouts();
}

function updateReadouts() {
    const { tauMax, phi, J, power, safetyFactor } = calcTorsion();
    $('torsion-stress-readout').textContent = formatSI(Math.abs(tauMax), 'Pa');
    $('torsion-twist-readout').textContent = (Math.abs(phi) * 180 / Math.PI).toFixed(2) + '°';
    $('torsion-j-readout').textContent = (J * 1e8).toFixed(4) + ' cm⁴';

    // Power readout
    const powerEl = $('torsion-power-readout');
    if (powerEl) {
        if (state.rpm > 0) {
            if (power >= 1e6) powerEl.textContent = (power / 1e6).toFixed(2) + ' MW';
            else if (power >= 1e3) powerEl.textContent = (power / 1e3).toFixed(2) + ' kW';
            else powerEl.textContent = power.toFixed(1) + ' W';
        } else {
            powerEl.textContent = 'N/A (set RPM)';
        }
    }

    // Safety factor
    const safetyEl = $('torsion-safety-readout');
    if (safetyEl) {
        if (safetyFactor === Infinity || safetyFactor > 99) {
            safetyEl.textContent = '—';
            safetyEl.className = 'readout-value';
        } else {
            safetyEl.textContent = safetyFactor.toFixed(2);
            safetyEl.className = 'readout-value ' + (safetyFactor >= 2 ? 'safe' : safetyFactor >= 1 ? 'warning' : 'danger');
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    $('torsion-material').addEventListener('change', e => {
        state.material = e.target.value;
        createShaft(); dirty = true;
    });

    $('torsion-length').addEventListener('input', e => {
        state.length = parseFloat(e.target.value);
        $('torsion-length-val').textContent = state.length.toFixed(1) + ' m';
        createShaft(); createWall(); createTorqueArrow(); dirty = true;
    });

    $('torsion-outer-r').addEventListener('input', e => {
        state.outerR = parseInt(e.target.value) / 1000;
        $('torsion-outer-r-val').textContent = parseInt(e.target.value) + ' mm';
        createShaft(); dirty = true;
    });

    $('torsion-hollow').addEventListener('change', e => {
        state.hollow = e.target.checked;
        $('torsion-inner-group').style.display = state.hollow ? 'block' : 'none';
        createShaft(); dirty = true;
    });

    $('torsion-inner-r').addEventListener('input', e => {
        state.innerR = parseInt(e.target.value) / 1000;
        $('torsion-inner-r-val').textContent = parseInt(e.target.value) + ' mm';
        if (state.innerR >= state.outerR) {
            state.innerR = state.outerR - 0.005;
        }
        createShaft(); dirty = true;
    });

    $('torsion-torque').addEventListener('input', e => {
        state.torque = parseFloat(e.target.value) * 1000;
        $('torsion-torque-val').textContent = parseFloat(e.target.value).toFixed(1) + ' kN·m';
        createTorqueArrow(); dirty = true;
    });

    // RPM slider
    const rpmEl = $('torsion-rpm');
    if (rpmEl) {
        rpmEl.addEventListener('input', e => {
            state.rpm = parseInt(e.target.value);
            $('torsion-rpm-val').textContent = state.rpm + ' rpm';
            dirty = true;
        });
    }

    $('torsion-deform-scale').addEventListener('input', e => {
        state.deformScale = parseInt(e.target.value);
        $('torsion-deform-scale-val').textContent = state.deformScale + 'x';
        dirty = true;
    });

    $('torsion-reset-btn').addEventListener('click', () => {
        state.material = 'steel'; state.length = 2; state.outerR = 0.05;
        state.innerR = 0.025; state.hollow = false; state.torque = 10000;
        state.rpm = 0; state.deformScale = 20;

        $('torsion-material').value = 'steel';
        $('torsion-length').value = 2; $('torsion-length-val').textContent = '2.0 m';
        $('torsion-outer-r').value = 50; $('torsion-outer-r-val').textContent = '50 mm';
        $('torsion-hollow').checked = false; $('torsion-inner-group').style.display = 'none';
        $('torsion-inner-r').value = 25; $('torsion-inner-r-val').textContent = '25 mm';
        $('torsion-torque').value = 10; $('torsion-torque-val').textContent = '10.0 kN·m';
        if (rpmEl) { rpmEl.value = 0; $('torsion-rpm-val').textContent = '0 rpm'; }
        $('torsion-deform-scale').value = 20; $('torsion-deform-scale-val').textContent = '20x';

        createShaft(); createWall(); createTorqueArrow(); dirty = true;
    });
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initTorsionModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    createShaft();
    createWall();
    createTorqueArrow();
    bindUI();

    registerModule('torsion', {
        activate() {
            group.visible = true;
            dirty = true;
        },
        deactivate() {
            group.visible = false;
        },
        update(dt, elapsed) {
            deformShaft();
            if (torqueArrow) {
                torqueArrow.rotation.x = Math.sin(elapsed * 2) * 0.05;
            }
        },
    });
}
