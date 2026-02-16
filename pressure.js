// ═══════════════════════════════════════════════════════════════
// pressure.js — Pressure Vessel Module
// Thin/thick-walled cylinder and sphere analysis
// with external pressure support
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, registerModule, MATERIALS, clamp, heatmapColor, formatSI } from './app.js';

const $ = id => document.getElementById(id);
let group;
let vesselMesh, vesselGeom, vesselMat;
let cutawayMesh, cutawayGeom, cutawayMat;
let stressArrows = [];
let dirty = true;

const state = {
    shape: 'cylinder',
    material: 'steel',
    radius: 0.5,        // m (inner radius)
    thickness: 0.01,    // m
    vesselLength: 2.0,  // m (cylinder only)
    pressure: 5e6,      // Pa (internal)
    extPressure: 0,     // Pa (external)
    cutaway: true,
};

function isThinWalled() {
    return state.radius / state.thickness > 10;
}

function calcPressure() {
    const ri = state.radius;
    const t = state.thickness;
    const ro = ri + t;
    const pi = state.pressure;
    const po = state.extPressure;
    const yieldStress = MATERIALS[state.material].yieldStress;

    let hoopStress, longStress, radialStress, vmStress;

    if (isThinWalled()) {
        // Net pressure for thin-wall approximation
        const pNet = pi - po;
        if (state.shape === 'cylinder') {
            hoopStress = pNet * ri / t;
            longStress = pNet * ri / (2 * t);
        } else {
            hoopStress = pNet * ri / (2 * t);
            longStress = hoopStress;
        }
        // Radial stress at inner surface (critical location): σ_r = -p_i
        // For thin-walled vessels, radial stress is typically negligible
        // compared to hoop/longitudinal, but we report the inner surface value
        radialStress = -pi;
    } else {
        // Thick-walled (Lamé equations) - at inner surface
        const k = ro / ri;
        if (state.shape === 'cylinder') {
            // σ_r(ri) = -pi, σ_θ(ri) = pi*(k²+1)/(k²-1) - po*2k²/(k²-1)
            const k2 = k * k;
            hoopStress = (pi * (k2 + 1) - po * 2 * k2) / (k2 - 1);
            longStress = (pi - po * k2) / (k2 - 1);
            radialStress = -pi;
        } else {
            // Thick-walled sphere: Lamé equations at inner surface (r = ri)
            // σ_θ = σ_φ = pi·ri³·(ro³ + 2·ri³) / (2·ri³·(ro³ - ri³))
            //              - po·ro³·(ri³ + 2·ri³) / (2·ri³·(ro³ - ri³))
            // Simplified at r = ri:
            const ri3 = ri * ri * ri;
            const ro3 = ro * ro * ro;
            const denom = 2 * (ro3 - ri3);
            hoopStress = pi * (ro3 + 2 * ri3) / denom - po * 2 * ro3 / denom;
            longStress = hoopStress; // sphere: σ_θ = σ_φ
            radialStress = -pi;
        }
    }

    // Von Mises
    vmStress = Math.sqrt(
        0.5 * (
            Math.pow(hoopStress - longStress, 2) +
            Math.pow(longStress - radialStress, 2) +
            Math.pow(radialStress - hoopStress, 2)
        )
    );

    const safety = vmStress > 0 ? yieldStress / vmStress : Infinity;
    const rtRatio = ri / t;

    return { hoopStress, longStress, radialStress, vmStress, safety, rtRatio };
}

// ═══════════════════════════════════════════════════════════════
// 3D Vessel
// ═══════════════════════════════════════════════════════════════

function createVessel() {
    if (vesselMesh) { group.remove(vesselMesh); vesselGeom.dispose(); vesselMat.dispose(); }
    if (cutawayMesh) { group.remove(cutawayMesh); cutawayGeom.dispose(); cutawayMat.dispose(); }
    stressArrows.forEach(a => group.remove(a));
    stressArrows = [];

    const { vmStress } = calcPressure();
    const yieldStress = MATERIALS[state.material].yieldStress;
    const stressRatio = clamp(vmStress / yieldStress, 0, 1);
    const c = heatmapColor(stressRatio);

    const matColor = new THREE.Color().copy(c);
    const outerR = state.radius + state.thickness;

    if (state.shape === 'cylinder') {
        const phiLength = state.cutaway ? Math.PI * 1.5 : Math.PI * 2;
        vesselGeom = new THREE.CylinderGeometry(outerR, outerR, state.vesselLength, 48, 1, false, 0, phiLength);
        vesselMat = new THREE.MeshStandardMaterial({
            color: matColor,
            roughness: 0.3,
            metalness: 0.7,
            side: THREE.DoubleSide,
        });
        vesselMesh = new THREE.Mesh(vesselGeom, vesselMat);
        vesselMesh.position.set(0, state.vesselLength / 2 + 0.5, 0);
        vesselMesh.castShadow = true;
        group.add(vesselMesh);

        if (state.cutaway) {
            cutawayGeom = new THREE.CylinderGeometry(state.radius, state.radius, state.vesselLength, 48, 1, false, 0, phiLength);
            cutawayMat = new THREE.MeshStandardMaterial({
                color: 0x2a3040,
                roughness: 0.5,
                metalness: 0.3,
                side: THREE.DoubleSide,
            });
            cutawayMesh = new THREE.Mesh(cutawayGeom, cutawayMat);
            cutawayMesh.position.copy(vesselMesh.position);
            group.add(cutawayMesh);

            const capGeo = new THREE.RingGeometry(state.radius, outerR, 48, 1, 0, phiLength);
            const capMat = new THREE.MeshStandardMaterial({ color: matColor, roughness: 0.4, metalness: 0.5, side: THREE.DoubleSide });

            const topCap = new THREE.Mesh(capGeo, capMat);
            topCap.rotation.x = -Math.PI / 2;
            topCap.position.set(0, state.vesselLength + 0.5, 0);
            group.add(topCap);
            stressArrows.push(topCap);

            const bottomCap = new THREE.Mesh(capGeo.clone(), capMat.clone());
            bottomCap.rotation.x = Math.PI / 2;
            bottomCap.position.set(0, 0.5, 0);
            group.add(bottomCap);
            stressArrows.push(bottomCap);
        }
    } else {
        const phiLength = state.cutaway ? Math.PI * 1.5 : Math.PI * 2;
        vesselGeom = new THREE.SphereGeometry(outerR, 48, 32, 0, phiLength);
        vesselMat = new THREE.MeshStandardMaterial({
            color: matColor,
            roughness: 0.3,
            metalness: 0.7,
            side: THREE.DoubleSide,
        });
        vesselMesh = new THREE.Mesh(vesselGeom, vesselMat);
        vesselMesh.position.set(0, outerR + 0.2, 0);
        vesselMesh.castShadow = true;
        group.add(vesselMesh);

        if (state.cutaway) {
            cutawayGeom = new THREE.SphereGeometry(state.radius, 48, 32, 0, phiLength);
            cutawayMat = new THREE.MeshStandardMaterial({
                color: 0x2a3040,
                roughness: 0.5,
                metalness: 0.3,
                side: THREE.DoubleSide,
            });
            cutawayMesh = new THREE.Mesh(cutawayGeom, cutawayMat);
            cutawayMesh.position.copy(vesselMesh.position);
            group.add(cutawayMesh);
        }
    }

    createStressArrows();
    dirty = false;
}

function createStressArrows() {
    const { hoopStress, longStress } = calcPressure();
    const pos = vesselMesh ? vesselMesh.position.clone() : new THREE.Vector3(0, 1, 0);
    const outerR = state.radius + state.thickness;

    if (Math.abs(hoopStress) > 0) {
        const color = hoopStress > 0 ? 0xf85149 : 0x58a6ff;
        const mag = clamp(Math.abs(hoopStress) / 1e8, 0.2, 1.0);

        for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 2) {
            if (state.cutaway && angle > Math.PI * 0.75 && angle < Math.PI * 1.75) continue;
            const dir = new THREE.Vector3(Math.cos(angle), 0, Math.sin(angle));
            const tangent = new THREE.Vector3(-Math.sin(angle), 0, Math.cos(angle));
            const origin = pos.clone().add(dir.clone().multiplyScalar(outerR + 0.05));

            const a1 = new THREE.ArrowHelper(tangent, origin, mag, color, 0.08, 0.05);
            const a2 = new THREE.ArrowHelper(tangent.clone().negate(), origin, mag, color, 0.08, 0.05);
            group.add(a1); group.add(a2);
            stressArrows.push(a1, a2);
        }
    }

    if (state.shape === 'cylinder' && Math.abs(longStress) > 0) {
        const color = longStress > 0 ? 0x58a6ff : 0xf85149;
        const mag = clamp(Math.abs(longStress) / 1e8, 0.15, 0.8);
        const yUp = new THREE.Vector3(0, 1, 0);
        const yDown = new THREE.Vector3(0, -1, 0);

        for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 2) {
            if (state.cutaway && angle > Math.PI * 0.75 && angle < Math.PI * 1.75) continue;
            const dir = new THREE.Vector3(Math.cos(angle), 0, Math.sin(angle));
            const origin = pos.clone().add(dir.clone().multiplyScalar(outerR + 0.05));

            const a1 = new THREE.ArrowHelper(yUp, origin.clone().sub(new THREE.Vector3(0, 0.1, 0)), mag, color, 0.06, 0.04);
            const a2 = new THREE.ArrowHelper(yDown, origin.clone().add(new THREE.Vector3(0, 0.1, 0)), mag, color, 0.06, 0.04);
            group.add(a1); group.add(a2);
            stressArrows.push(a1, a2);
        }
    }
}

function updateReadouts() {
    const { hoopStress, longStress, radialStress, vmStress, rtRatio, safety } = calcPressure();

    $('pressure-hoop-readout').textContent = formatSI(hoopStress, 'Pa');
    $('pressure-long-readout').textContent = formatSI(longStress, 'Pa');
    $('pressure-vm-readout').textContent = formatSI(vmStress, 'Pa');
    $('pressure-rt-readout').textContent = rtRatio.toFixed(1);
    $('pressure-safety-readout').textContent = safety === Infinity ? '∞' : safety.toFixed(2);

    // Radial stress readout
    const radialEl = $('pressure-radial-readout');
    if (radialEl) radialEl.textContent = formatSI(radialStress, 'Pa');

    // Safety color
    const safetyEl = $('pressure-safety-readout');
    if (safety < 1) {
        safetyEl.style.color = '#f85149';
    } else if (safety < 2) {
        safetyEl.style.color = '#d29922';
    } else {
        safetyEl.style.color = '#3fb950';
    }

    // Thin/thick note
    const note = $('pressure-thin-note');
    if (note) {
        if (isThinWalled()) {
            note.textContent = 'Analysis: Thin-walled (r/t > 10)';
            note.className = 'status-bar';
        } else {
            note.textContent = 'Analysis: Thick-walled (Lamé equations)';
            note.className = 'status-bar success';
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    document.querySelectorAll('input[name="vessel-shape"]').forEach(radio => {
        radio.addEventListener('change', e => {
            state.shape = e.target.value;
            $('pressure-vessel-length-group').style.display = state.shape === 'cylinder' ? 'block' : 'none';
            createVessel(); updateReadouts();
        });
    });

    $('pressure-material').addEventListener('change', e => {
        state.material = e.target.value;
        createVessel(); updateReadouts();
    });

    $('pressure-radius').addEventListener('input', e => {
        state.radius = parseInt(e.target.value) / 1000;
        $('pressure-radius-val').textContent = parseInt(e.target.value) + ' mm';
        createVessel(); updateReadouts();
    });

    $('pressure-thickness').addEventListener('input', e => {
        state.thickness = parseInt(e.target.value) / 1000;
        $('pressure-thickness-val').textContent = parseInt(e.target.value) + ' mm';
        createVessel(); updateReadouts();
    });

    $('pressure-vessel-length').addEventListener('input', e => {
        state.vesselLength = parseFloat(e.target.value);
        $('pressure-vessel-length-val').textContent = state.vesselLength.toFixed(1) + ' m';
        createVessel(); updateReadouts();
    });

    $('pressure-internal').addEventListener('input', e => {
        state.pressure = parseFloat(e.target.value) * 1e6;
        $('pressure-internal-val').textContent = parseFloat(e.target.value).toFixed(1) + ' MPa';
        createVessel(); updateReadouts();
    });

    // External pressure
    const extEl = $('pressure-external');
    if (extEl) {
        extEl.addEventListener('input', e => {
            state.extPressure = parseFloat(e.target.value) * 1e6;
            $('pressure-external-val').textContent = parseFloat(e.target.value).toFixed(1) + ' MPa';
            createVessel(); updateReadouts();
        });
    }

    $('pressure-cutaway').addEventListener('change', e => {
        state.cutaway = e.target.checked;
        createVessel(); updateReadouts();
    });

    $('pressure-reset-btn').addEventListener('click', () => {
        state.shape = 'cylinder'; state.material = 'steel';
        state.radius = 0.5; state.thickness = 0.01; state.vesselLength = 2.0;
        state.pressure = 5e6; state.extPressure = 0; state.cutaway = true;

        document.querySelector('input[name="vessel-shape"][value="cylinder"]').checked = true;
        $('pressure-material').value = 'steel';
        $('pressure-radius').value = 500; $('pressure-radius-val').textContent = '500 mm';
        $('pressure-thickness').value = 10; $('pressure-thickness-val').textContent = '10 mm';
        $('pressure-vessel-length').value = 2; $('pressure-vessel-length-val').textContent = '2.0 m';
        $('pressure-internal').value = 5; $('pressure-internal-val').textContent = '5.0 MPa';
        if (extEl) { extEl.value = 0; $('pressure-external-val').textContent = '0.0 MPa'; }
        $('pressure-cutaway').checked = true;
        $('pressure-vessel-length-group').style.display = 'block';

        createVessel(); updateReadouts();
    });
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initPressureModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    createVessel();
    bindUI();
    updateReadouts();

    registerModule('pressure', {
        activate() {
            group.visible = true;
            dirty = true;
        },
        deactivate() {
            group.visible = false;
        },
        update(dt, elapsed) {
            if (vesselMesh && state.pressure > 0) {
                const pulse = 1 + Math.sin(elapsed * 3) * 0.005;
                vesselMesh.scale.set(pulse, 1, pulse);
            }
        },
    });
}
