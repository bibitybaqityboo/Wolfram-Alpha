// ═══════════════════════════════════════════════════════════════
// mohr.js — Mohr's Circle Module
// Interactive 2D/3D stress transformation with 3D stress element
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { scene, camera, registerModule, overlayCanvas, overlayCtx, clamp } from './app.js';

const $ = id => document.getElementById(id);
let group;
let cubeMesh, cubeEdges;
let stressArrows = [];
let dirty = true;

const state = {
    sx: 80, sy: -40, txy: 30, sz: 0, angle: 0,
};

function calcMohr() {
    const { sx, sy, txy, sz } = state;
    const center = (sx + sy) / 2;
    const R = Math.sqrt(Math.pow((sx - sy) / 2, 2) + txy * txy);
    const s1 = center + R;
    const s2 = center - R;
    const s3 = sz; // third principal stress for 3D
    const tmax = R;
    const thetaP = (0.5 * Math.atan2(2 * txy, sx - sy)) * 180 / Math.PI;

    // For 3D Mohr: sort principal stresses
    const principals = [s1, s2, s3].sort((a, b) => b - a);
    const sigma1 = principals[0];
    const sigma2 = principals[1];
    const sigma3 = principals[2];
    const tmax3D = (sigma1 - sigma3) / 2;

    // Transformed stresses at angle theta
    const theta = state.angle * Math.PI / 180;
    const sxp = center + ((sx - sy) / 2) * Math.cos(2 * theta) + txy * Math.sin(2 * theta);
    const syp = center - ((sx - sy) / 2) * Math.cos(2 * theta) - txy * Math.sin(2 * theta);
    const txyp = -((sx - sy) / 2) * Math.sin(2 * theta) + txy * Math.cos(2 * theta);

    // Von Mises (3D)
    const vm = Math.sqrt(0.5 * ((sigma1 - sigma2) ** 2 + (sigma2 - sigma3) ** 2 + (sigma3 - sigma1) ** 2));

    return { center, R, s1, s2, s3: sz, tmax, tmax3D, thetaP, sxp, syp, txyp, vm, sigma1, sigma2, sigma3 };
}

// ═══════════════════════════════════════════════════════════════
// 3D Stress Element
// ═══════════════════════════════════════════════════════════════

function create3DElement() {
    const geo = new THREE.BoxGeometry(1.6, 1.6, 1.6);
    const mat = new THREE.MeshStandardMaterial({
        color: 0x2a3040,
        transparent: true,
        opacity: 0.3,
        roughness: 0.5,
        metalness: 0.3,
        side: THREE.DoubleSide,
    });
    cubeMesh = new THREE.Mesh(geo, mat);
    cubeMesh.position.set(0, 1.2, 0);
    group.add(cubeMesh);

    const edgeGeo = new THREE.EdgesGeometry(geo);
    const edgeMat = new THREE.LineBasicMaterial({ color: 0x58a6ff, linewidth: 1.5 });
    cubeEdges = new THREE.LineSegments(edgeGeo, edgeMat);
    cubeEdges.position.copy(cubeMesh.position);
    group.add(cubeEdges);
}

function updateStressArrows() {
    stressArrows.forEach(a => group.remove(a));
    stressArrows = [];

    const { sxp, syp, txyp } = calcMohr();
    const theta = state.angle * Math.PI / 180;
    const center = cubeMesh.position.clone();
    const size = 0.8;

    function addNormalStress(axis, value, color) {
        if (Math.abs(value) < 1) return;
        const mag = clamp(Math.abs(value) / 100, 0.2, 1.5);
        const dir1 = axis.clone();
        const dir2 = axis.clone().negate();

        if (value > 0) {
            const o1 = center.clone().add(axis.clone().multiplyScalar(size));
            const o2 = center.clone().add(axis.clone().multiplyScalar(-size));
            const a1 = new THREE.ArrowHelper(dir1, o1, mag, color, 0.12, 0.08);
            const a2 = new THREE.ArrowHelper(dir2, o2, mag, color, 0.12, 0.08);
            group.add(a1); group.add(a2);
            stressArrows.push(a1, a2);
        } else {
            const o1 = center.clone().add(axis.clone().multiplyScalar(size + mag));
            const o2 = center.clone().add(axis.clone().multiplyScalar(-size - mag));
            const a1 = new THREE.ArrowHelper(dir2.clone().negate().negate(), o1, mag, color, 0.12, 0.08);
            const a2 = new THREE.ArrowHelper(dir1.clone().negate().negate(), o2, mag, color, 0.12, 0.08);
            group.add(a1); group.add(a2);
            stressArrows.push(a1, a2);
        }
    }

    function addShearStress(tangent, normal, value, color) {
        if (Math.abs(value) < 1) return;
        const mag = clamp(Math.abs(value) / 100, 0.15, 1.0);
        const dir = value > 0 ? tangent.clone() : tangent.clone().negate();

        const o1 = center.clone().add(normal.clone().multiplyScalar(size));
        const o2 = center.clone().add(normal.clone().multiplyScalar(-size));
        const a1 = new THREE.ArrowHelper(dir, o1.clone().sub(dir.clone().multiplyScalar(mag / 2)), mag, color, 0.08, 0.06);
        const a2 = new THREE.ArrowHelper(dir.clone().negate(), o2.clone().add(dir.clone().multiplyScalar(mag / 2)), mag, color, 0.08, 0.06);
        group.add(a1); group.add(a2);
        stressArrows.push(a1, a2);
    }

    // Rotated axes (xy plane)
    const xAxis = new THREE.Vector3(Math.cos(theta), 0, Math.sin(theta));
    const yAxis = new THREE.Vector3(-Math.sin(theta), 0, Math.cos(theta));
    const zAxis = new THREE.Vector3(0, 1, 0);

    addNormalStress(xAxis, sxp, sxp > 0 ? 0xf85149 : 0x58a6ff);
    addNormalStress(yAxis, syp, syp > 0 ? 0xf85149 : 0x58a6ff);
    addShearStress(yAxis, xAxis, txyp, 0x3fb950);

    // σz arrows (always along vertical)
    if (Math.abs(state.sz) > 1) {
        addNormalStress(zAxis, state.sz, state.sz > 0 ? 0xf85149 : 0x58a6ff);
    }

    cubeMesh.rotation.y = theta;
    cubeEdges.rotation.y = theta;
}

// ═══════════════════════════════════════════════════════════════
// 2D/3D Mohr's Circle Overlay
// ═══════════════════════════════════════════════════════════════

function drawMohrCircle() {
    const canvas = overlayCanvas;
    const ctx = overlayCtx;
    const w = canvas.width / window.devicePixelRatio;
    const h = canvas.height / window.devicePixelRatio;

    ctx.clearRect(0, 0, w, h);

    const result = calcMohr();
    const { center, R, s1, s2, tmax, thetaP, sxp, syp, txyp, sigma1, sigma2, sigma3, tmax3D } = result;
    const { sx, sy, txy, sz } = state;

    // Scale to fit — consider 3D principals
    const allVals = [Math.abs(sigma1), Math.abs(sigma2), Math.abs(sigma3), Math.abs(tmax3D)];
    const maxVal = Math.max(...allVals, 50) * 1.3;
    const scale = (Math.min(w, h) * 0.35) / maxVal;
    const cx = w / 2;
    const cy = h / 2;

    // Grid
    ctx.strokeStyle = 'rgba(255,255,255,0.04)';
    ctx.lineWidth = 0.5;
    const gridStep = maxVal / 5;
    for (let i = -5; i <= 5; i++) {
        const px = cx + i * gridStep * scale;
        ctx.beginPath(); ctx.moveTo(px, 0); ctx.lineTo(px, h); ctx.stroke();
        const py = cy + i * gridStep * scale;
        ctx.beginPath(); ctx.moveTo(0, py); ctx.lineTo(w, py); ctx.stroke();
    }

    // Axes
    ctx.strokeStyle = 'rgba(255,255,255,0.15)';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(0, cy); ctx.lineTo(w, cy); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(cx, 0); ctx.lineTo(cx, h); ctx.stroke();

    // Axis labels
    ctx.fillStyle = 'rgba(255,255,255,0.4)';
    ctx.font = '11px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('σ (MPa)', w - 60, cy - 8);
    ctx.fillText('τ (MPa)', cx + 8, 16);

    // 3D Mohr: draw three circles if σz ≠ 0
    const is3D = Math.abs(sz) > 0.5;
    if (is3D) {
        // Circle 1: σ₁ – σ₃ (largest)
        const c13 = (sigma1 + sigma3) / 2;
        const r13 = (sigma1 - sigma3) / 2;
        ctx.strokeStyle = 'rgba(88, 166, 255, 0.5)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(cx + c13 * scale, cy, Math.abs(r13) * scale, 0, 2 * Math.PI);
        ctx.stroke();
        // Fill
        const grad1 = ctx.createRadialGradient(cx + c13 * scale, cy, 0, cx + c13 * scale, cy, Math.abs(r13) * scale);
        grad1.addColorStop(0, 'rgba(88, 166, 255, 0.06)');
        grad1.addColorStop(1, 'rgba(88, 166, 255, 0.01)');
        ctx.fillStyle = grad1;
        ctx.fill();

        // Circle 2: σ₁ – σ₂
        const c12 = (sigma1 + sigma2) / 2;
        const r12 = (sigma1 - sigma2) / 2;
        ctx.strokeStyle = 'rgba(163, 113, 247, 0.5)';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(cx + c12 * scale, cy, Math.abs(r12) * scale, 0, 2 * Math.PI);
        ctx.stroke();

        // Circle 3: σ₂ – σ₃
        const c23 = (sigma2 + sigma3) / 2;
        const r23 = (sigma2 - sigma3) / 2;
        ctx.strokeStyle = 'rgba(63, 185, 80, 0.5)';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(cx + c23 * scale, cy, Math.abs(r23) * scale, 0, 2 * Math.PI);
        ctx.stroke();

        // Label 3D
        ctx.fillStyle = 'rgba(255,255,255,0.3)';
        ctx.font = '9px Inter, sans-serif';
        ctx.fillText('3D Mohr', 12, h - 8);
    } else {
        // Standard 2D circle
        ctx.strokeStyle = 'rgba(88, 166, 255, 0.6)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(cx + center * scale, cy, R * scale, 0, 2 * Math.PI);
        ctx.stroke();

        const grad = ctx.createRadialGradient(cx + center * scale, cy, 0, cx + center * scale, cy, R * scale);
        grad.addColorStop(0, 'rgba(88, 166, 255, 0.08)');
        grad.addColorStop(1, 'rgba(88, 166, 255, 0.02)');
        ctx.fillStyle = grad;
        ctx.fill();
    }

    // Original stress point (σx, τxy)
    const px1 = cx + sx * scale;
    const py1 = cy - txy * scale;
    ctx.fillStyle = '#f85149';
    ctx.beginPath(); ctx.arc(px1, py1, 5, 0, 2 * Math.PI); ctx.fill();
    ctx.fillStyle = 'rgba(248,81,73,0.8)';
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(`X(${sx}, ${txy})`, px1 + 8, py1 - 8);

    // Original stress point (σy, -τxy)
    const px2 = cx + sy * scale;
    const py2 = cy + txy * scale;
    ctx.fillStyle = '#58a6ff';
    ctx.beginPath(); ctx.arc(px2, py2, 5, 0, 2 * Math.PI); ctx.fill();
    ctx.fillStyle = 'rgba(88,166,255,0.8)';
    ctx.fillText(`Y(${sy}, ${-txy})`, px2 + 8, py2 + 14);

    // Dashed line connecting original points
    ctx.strokeStyle = 'rgba(255,255,255,0.15)';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.beginPath(); ctx.moveTo(px1, py1); ctx.lineTo(px2, py2); ctx.stroke();
    ctx.setLineDash([]);

    // Transformed stress point
    const px3 = cx + sxp * scale;
    const py3 = cy - txyp * scale;
    ctx.fillStyle = '#a371f7';
    ctx.beginPath(); ctx.arc(px3, py3, 6, 0, 2 * Math.PI); ctx.fill();
    ctx.strokeStyle = '#a371f7';
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.fillStyle = 'rgba(163,113,247,0.9)';
    ctx.font = 'bold 10px Inter, sans-serif';
    ctx.fillText(`σ'=(${sxp.toFixed(1)}, ${txyp.toFixed(1)})`, px3 + 8, py3 - 8);

    // Principal stress markers
    ctx.fillStyle = '#3fb950';
    const pxS1 = cx + sigma1 * scale;
    const pxS2 = cx + sigma2 * scale;
    const pxS3 = cx + sigma3 * scale;
    ctx.beginPath(); ctx.arc(pxS1, cy, 4, 0, 2 * Math.PI); ctx.fill();
    ctx.beginPath(); ctx.arc(pxS2, cy, 4, 0, 2 * Math.PI); ctx.fill();
    if (is3D) {
        ctx.beginPath(); ctx.arc(pxS3, cy, 4, 0, 2 * Math.PI); ctx.fill();
    }

    ctx.fillStyle = 'rgba(63,185,80,0.8)';
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(`σ₁=${sigma1.toFixed(1)}`, pxS1 + 6, cy + 16);
    ctx.fillText(`σ₂=${sigma2.toFixed(1)}`, pxS2 - 55, cy + 16);
    if (is3D) {
        ctx.fillText(`σ₃=${sigma3.toFixed(1)}`, pxS3 - 55, cy - 8);
    }

    // Max shear markers
    const tmaxDisplay = is3D ? tmax3D : tmax;
    const centerForTmax = is3D ? (sigma1 + sigma3) / 2 : center;
    ctx.fillStyle = '#d29922';
    ctx.beginPath(); ctx.arc(cx + centerForTmax * scale, cy - tmaxDisplay * scale, 3, 0, 2 * Math.PI); ctx.fill();
    ctx.beginPath(); ctx.arc(cx + centerForTmax * scale, cy + tmaxDisplay * scale, 3, 0, 2 * Math.PI); ctx.fill();

    // Title
    ctx.fillStyle = 'rgba(255,255,255,0.6)';
    ctx.font = 'bold 12px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(is3D ? "3D Mohr's Circle" : "Mohr's Circle", 12, 20);
}

// ═══════════════════════════════════════════════════════════════
// Readouts
// ═══════════════════════════════════════════════════════════════

function updateReadouts() {
    const { sigma1, sigma2, sigma3, tmax, tmax3D, thetaP, vm } = calcMohr();
    const is3D = Math.abs(state.sz) > 0.5;

    $('mohr-s1-readout').textContent = sigma1.toFixed(1) + ' MPa';
    $('mohr-s2-readout').textContent = sigma2.toFixed(1) + ' MPa';

    const s3El = $('mohr-s3-readout');
    if (s3El) s3El.textContent = sigma3.toFixed(1) + ' MPa';

    $('mohr-tmax-readout').textContent = (is3D ? tmax3D : tmax).toFixed(1) + ' MPa';
    $('mohr-tp-readout').textContent = thetaP.toFixed(1) + '°';
    $('mohr-vm-readout').textContent = vm.toFixed(1) + ' MPa';

    // Tresca yield criterion: τ_max = (σ₁ - σ₃) / 2
    const tresca = (is3D ? tmax3D : tmax);
    const trescaEl = $('mohr-tresca-readout');
    if (trescaEl) trescaEl.textContent = tresca.toFixed(1) + ' MPa';
}

// ═══════════════════════════════════════════════════════════════
// UI Bindings
// ═══════════════════════════════════════════════════════════════

function bindUI() {
    $('mohr-sx').addEventListener('input', e => {
        state.sx = parseInt(e.target.value);
        $('mohr-sx-val').textContent = state.sx + ' MPa';
        dirty = true;
    });
    $('mohr-sy').addEventListener('input', e => {
        state.sy = parseInt(e.target.value);
        $('mohr-sy-val').textContent = state.sy + ' MPa';
        dirty = true;
    });
    $('mohr-txy').addEventListener('input', e => {
        state.txy = parseInt(e.target.value);
        $('mohr-txy-val').textContent = state.txy + ' MPa';
        dirty = true;
    });

    // 3D stress (σz)
    const szEl = $('mohr-sz');
    if (szEl) {
        szEl.addEventListener('input', e => {
            state.sz = parseInt(e.target.value);
            $('mohr-sz-val').textContent = state.sz + ' MPa';
            dirty = true;
        });
    }

    $('mohr-angle').addEventListener('input', e => {
        state.angle = parseInt(e.target.value);
        $('mohr-angle-val').textContent = state.angle + '°';
        dirty = true;
    });
    $('mohr-reset-btn').addEventListener('click', () => {
        state.sx = 80; state.sy = -40; state.txy = 30; state.sz = 0; state.angle = 0;
        $('mohr-sx').value = 80; $('mohr-sx-val').textContent = '80 MPa';
        $('mohr-sy').value = -40; $('mohr-sy-val').textContent = '-40 MPa';
        $('mohr-txy').value = 30; $('mohr-txy-val').textContent = '30 MPa';
        if (szEl) { szEl.value = 0; $('mohr-sz-val').textContent = '0 MPa'; }
        $('mohr-angle').value = 0; $('mohr-angle-val').textContent = '0°';
        dirty = true;
    });
}

// ═══════════════════════════════════════════════════════════════
// Module Interface
// ═══════════════════════════════════════════════════════════════

export function initMohrModule() {
    group = new THREE.Group();
    group.visible = false;
    scene.add(group);

    create3DElement();
    bindUI();

    registerModule('mohr', {
        activate() {
            group.visible = true;
            dirty = true;
        },
        deactivate() {
            group.visible = false;
        },
        update(dt, elapsed) {
            if (dirty) {
                dirty = false;
                updateStressArrows();
                drawMohrCircle();
                updateReadouts();
            }
        },
    });
}
