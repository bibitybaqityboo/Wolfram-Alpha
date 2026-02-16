// ═══════════════════════════════════════════════════════════════
// app.js — MechSim: Mechanics of Materials Simulator
// Core scene, module switching, environments, engine utilities
// ═══════════════════════════════════════════════════════════════

import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { initHelpSystem } from './help.js';

// ── Material Database ──
export const MATERIALS = {
    steel: { name: 'Steel', E: 200e9, G: 79e9, nu: 0.30, yieldStress: 250e6, alpha: 12e-6, color: 0x8899aa, density: 7850 },
    aluminum: { name: 'Aluminum', E: 69e9, G: 26e9, nu: 0.33, yieldStress: 270e6, alpha: 23e-6, color: 0xb0b8c0, density: 2700 },
    wood: { name: 'Wood', E: 12e9, G: 0.7e9, nu: 0.35, yieldStress: 40e6, alpha: 5e-6, color: 0x8B6914, density: 600 },
    concrete: { name: 'Concrete', E: 30e9, G: 12.5e9, nu: 0.20, yieldStress: 30e6, alpha: 10e-6, color: 0x999999, density: 2400 },
    titanium: { name: 'Titanium', E: 116e9, G: 44e9, nu: 0.34, yieldStress: 880e6, alpha: 8.6e-6, color: 0xa0a8b0, density: 4500 },
    copper: { name: 'Copper', E: 117e9, G: 44e9, nu: 0.34, yieldStress: 70e6, alpha: 16.5e-6, color: 0xd4875e, density: 8960 },
    'cast-iron': { name: 'Cast Iron', E: 170e9, G: 65e9, nu: 0.26, yieldStress: 130e6, alpha: 10e-6, color: 0x666666, density: 7200 },
};

// ── Tensile Test Material Properties (for stress-strain curves) ──
export const TENSILE_MATERIALS = {
    steel: { E: 200e3, sigmaY: 250, sigmaUlt: 400, strainUlt: 0.20, strainFracture: 0.30, n: 0.15, color: '#58a6ff' },
    aluminum: { E: 69e3, sigmaY: 270, sigmaUlt: 310, strainUlt: 0.12, strainFracture: 0.17, n: 0.20, color: '#b0b8c0' },
    copper: { E: 117e3, sigmaY: 70, sigmaUlt: 220, strainUlt: 0.35, strainFracture: 0.45, n: 0.50, color: '#d4875e' },
    titanium: { E: 116e3, sigmaY: 880, sigmaUlt: 950, strainUlt: 0.10, strainFracture: 0.14, n: 0.05, color: '#a371f7' },
    'cast-iron': { E: 170e3, sigmaY: 130, sigmaUlt: 200, strainUlt: 0.005, strainFracture: 0.006, n: 0.01, color: '#7d8590' },
};

// ── Helper ──
const $ = id => document.getElementById(id);

export function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

export function formatSI(val, unit, decimals = 1) {
    const abs = Math.abs(val);
    if (abs === 0) return '0 ' + unit;
    if (abs >= 1e9) return (val / 1e9).toFixed(decimals) + ' G' + unit;
    if (abs >= 1e6) return (val / 1e6).toFixed(decimals) + ' M' + unit;
    if (abs >= 1e3) return (val / 1e3).toFixed(decimals) + ' k' + unit;
    if (abs >= 1) return val.toFixed(decimals) + ' ' + unit;
    if (abs >= 1e-3) return (val * 1e3).toFixed(decimals) + ' m' + unit;
    if (abs >= 1e-6) return (val * 1e6).toFixed(decimals) + ' μ' + unit;
    return val.toExponential(2) + ' ' + unit;
}

export function heatmapColor(t) {
    t = clamp(t, 0, 1);
    const r = clamp(t < 0.5 ? 0 : (t - 0.5) * 2, 0, 1);
    const g = t < 0.5 ? t * 2 : (1 - t) * 2;
    const b = clamp(t < 0.5 ? 1 - t * 2 : 0, 0, 1);
    return new THREE.Color(r, g, b);
}

export function lerp(a, b, t) { return a + (b - a) * t; }

// ═══════════════════════════════════════════════════════════════
// Material Cache — Reuse materials instead of recreating
// ═══════════════════════════════════════════════════════════════
const materialCache = new Map();
export function getCachedMaterial(color, opts = {}) {
    const key = `${color}-${opts.roughness || 0.4}-${opts.metalness || 0.3}-${opts.transparent || false}`;
    if (materialCache.has(key)) return materialCache.get(key);
    const mat = new THREE.MeshStandardMaterial({
        color,
        roughness: opts.roughness ?? 0.4,
        metalness: opts.metalness ?? 0.3,
        transparent: opts.transparent || false,
        opacity: opts.opacity ?? 1.0,
        ...opts,
    });
    materialCache.set(key, mat);
    return mat;
}

// ═══════════════════════════════════════════════════════════════
// Disposal Utility — Proper cleanup
// ═══════════════════════════════════════════════════════════════
export function disposeObject(obj) {
    if (!obj) return;
    obj.traverse(child => {
        if (child.geometry) child.geometry.dispose();
        if (child.material) {
            if (Array.isArray(child.material)) {
                child.material.forEach(m => {
                    const isCached = [...materialCache.values()].some(cm => cm === m);
                    if (!isCached) m.dispose();
                });
            } else {
                // Only dispose non-cached materials (check values, not keys)
                const isCached = [...materialCache.values()].some(m => m === child.material);
                if (!isCached) {
                    child.material.dispose();
                }
            }
        }
    });
    if (obj.parent) obj.parent.remove(obj);
}

// ═══════════════════════════════════════════════════════════════
// Scene Setup
// ═══════════════════════════════════════════════════════════════
const container = $('canvas-container');

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x040810);
scene.fog = new THREE.FogExp2(0x040810, 0.025);

const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 150);
camera.position.set(5, 4, 6);

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.2;
renderer.outputColorSpace = THREE.SRGBColorSpace;
container.appendChild(renderer.domElement);

const orbitControls = new OrbitControls(camera, renderer.domElement);
orbitControls.enableDamping = true;
orbitControls.dampingFactor = 0.08;
orbitControls.minDistance = 2;
orbitControls.maxDistance = 30;
orbitControls.target.set(0, 0.5, 0);

// ── Lighting ──
const ambientLight = new THREE.AmbientLight(0x404868, 0.7);
scene.add(ambientLight);

const mainLight = new THREE.DirectionalLight(0xffffff, 2.0);
mainLight.position.set(6, 10, 5);
mainLight.castShadow = true;
mainLight.shadow.mapSize.set(2048, 2048);
mainLight.shadow.camera.left = -10;
mainLight.shadow.camera.right = 10;
mainLight.shadow.camera.top = 10;
mainLight.shadow.camera.bottom = -10;
mainLight.shadow.camera.near = 0.5;
mainLight.shadow.camera.far = 30;
mainLight.shadow.bias = -0.001;
scene.add(mainLight);

const fillLight = new THREE.DirectionalLight(0x8888ff, 0.4);
fillLight.position.set(-3, 5, 2);
scene.add(fillLight);

const rimLight = new THREE.DirectionalLight(0xa371f7, 0.35);
rimLight.position.set(0, 3, -5);
scene.add(rimLight);

// ── Environment: Ground with subtle reflection ──
const groundGeo = new THREE.PlaneGeometry(60, 60);
const groundMat = new THREE.MeshStandardMaterial({
    color: 0x080c12,
    roughness: 0.85,
    metalness: 0.15,
    envMapIntensity: 0.3,
});
const ground = new THREE.Mesh(groundGeo, groundMat);
ground.rotation.x = -Math.PI / 2;
ground.position.y = -0.01;
ground.receiveShadow = true;
scene.add(ground);

// ── Grid ──
const gridHelper = new THREE.GridHelper(30, 60, 0x1a2535, 0x0f1620);
gridHelper.position.y = 0;
scene.add(gridHelper);

// ── Ambient particles (floating dust motes) ──
const particleCount = 120;
const particleGeo = new THREE.BufferGeometry();
const particlePositions = new Float32Array(particleCount * 3);
for (let i = 0; i < particleCount; i++) {
    particlePositions[i * 3] = (Math.random() - 0.5) * 20;
    particlePositions[i * 3 + 1] = Math.random() * 8;
    particlePositions[i * 3 + 2] = (Math.random() - 0.5) * 20;
}
particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePositions, 3));
const particleMat = new THREE.PointsMaterial({
    color: 0x58a6ff,
    size: 0.03,
    transparent: true,
    opacity: 0.3,
    blending: THREE.AdditiveBlending,
    depthWrite: false
});
const particles = new THREE.Points(particleGeo, particleMat);
scene.add(particles);

// ═══════════════════════════════════════════════════════════════
// Environment Backgrounds — Context per module
// ═══════════════════════════════════════════════════════════════
const environments = {
    beam: { bgColor: 0x060a10, fogColor: 0x060a10, fogDensity: 0.025, accentHue: 0x58a6ff },
    mohr: { bgColor: 0x08080f, fogColor: 0x08080f, fogDensity: 0.02, accentHue: 0xa371f7 },
    torsion: { bgColor: 0x060a10, fogColor: 0x060a10, fogDensity: 0.025, accentHue: 0x3fb950 },
    column: { bgColor: 0x0a0810, fogColor: 0x0a0810, fogDensity: 0.025, accentHue: 0xd29922 },
    pressure: { bgColor: 0x0a0808, fogColor: 0x0a0808, fogDensity: 0.02, accentHue: 0xf85149 },
    truss: { bgColor: 0x060a10, fogColor: 0x060a10, fogDensity: 0.025, accentHue: 0x58a6ff },
    material: { bgColor: 0x08090c, fogColor: 0x08090c, fogDensity: 0.018, accentHue: 0x58a6ff },
};

function setEnvironment(name) {
    const env = environments[name] || environments.beam;
    const bgColor = new THREE.Color(env.bgColor);
    scene.background = bgColor;
    scene.fog.color.copy(bgColor);
    scene.fog.density = env.fogDensity;
    particleMat.color.set(env.accentHue);
}

// ═══════════════════════════════════════════════════════════════
// Module System
// ═══════════════════════════════════════════════════════════════
const modules = {};
let activeModule = null;

export function registerModule(name, mod) {
    modules[name] = mod;
}

function switchModule(name) {
    // Hide all panels
    document.querySelectorAll('.panel').forEach(p => p.classList.add('hidden'));
    // Deactivate current
    if (activeModule && modules[activeModule] && modules[activeModule].deactivate) {
        modules[activeModule].deactivate();
    }
    // Activate new
    activeModule = name;
    const panelId = name + '-controls';
    const panel = $(panelId);
    if (panel) panel.classList.remove('hidden');
    if (modules[name] && modules[name].activate) {
        modules[name].activate();
    }
    // Update tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === name);
    });
    // Show/hide overlay canvas
    const overlay = $('overlay-canvas');
    if (name === 'mohr' || name === 'material') {
        overlay.classList.add('visible');
    } else {
        overlay.classList.remove('visible');
    }
    // Set environment
    setEnvironment(name);
    // Update bottom bar
    const moduleNames = {
        beam: 'Beam Analysis', mohr: "Mohr's Circle", torsion: 'Torsion',
        column: 'Column Buckling', pressure: 'Pressure Vessels',
        truss: 'Truss Analysis', material: 'Material Testing'
    };
    const barModule = $('bar-module');
    if (barModule) barModule.textContent = 'Module: ' + (moduleNames[name] || name);
}

// ── Tab Clicks ──
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => switchModule(btn.dataset.mode));
});

// ═══════════════════════════════════════════════════════════════
// Overlay Canvas (2D rendering for Mohr / Stress-Strain)
// ═══════════════════════════════════════════════════════════════
const overlayCanvas = $('overlay-canvas');
const overlayCtx = overlayCanvas.getContext('2d');

function resizeOverlay() {
    const rect = overlayCanvas.getBoundingClientRect();
    overlayCanvas.width = rect.width * window.devicePixelRatio;
    overlayCanvas.height = rect.height * window.devicePixelRatio;
    overlayCtx.setTransform(1, 0, 0, 1, 0, 0); // reset before scaling to prevent accumulation
    overlayCtx.scale(window.devicePixelRatio, window.devicePixelRatio);
}
resizeOverlay();

export { scene, camera, renderer, orbitControls, overlayCanvas, overlayCtx };

// ═══════════════════════════════════════════════════════════════
// FPS Counter
// ═══════════════════════════════════════════════════════════════
let frameCount = 0;
let lastFpsTime = performance.now();
const fpsEl = $('bar-fps');

function updateFPS() {
    frameCount++;
    const now = performance.now();
    if (now - lastFpsTime >= 1000) {
        const fps = Math.round(frameCount * 1000 / (now - lastFpsTime));
        if (fpsEl) fpsEl.textContent = fps;
        frameCount = 0;
        lastFpsTime = now;
    }
}

// ═══════════════════════════════════════════════════════════════
// Animation Loop
// ═══════════════════════════════════════════════════════════════
const clock = new THREE.Clock();

function animate() {
    requestAnimationFrame(animate);
    const dt = clock.getDelta();
    const elapsed = clock.getElapsedTime();

    orbitControls.update();

    // Animate particles
    const positions = particleGeo.attributes.position.array;
    for (let i = 0; i < particleCount; i++) {
        positions[i * 3 + 1] += Math.sin(elapsed * 0.3 + i) * 0.001;
        if (positions[i * 3 + 1] > 8) positions[i * 3 + 1] = 0;
    }
    particleGeo.attributes.position.needsUpdate = true;

    // Update active module
    if (activeModule && modules[activeModule] && modules[activeModule].update) {
        modules[activeModule].update(dt, elapsed);
    }

    renderer.render(scene, camera);
    updateFPS();
}

// ── Resize ──
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    resizeOverlay();
});

// ═══════════════════════════════════════════════════════════════
// Import & Initialize Modules
// ═══════════════════════════════════════════════════════════════
import { initBeamModule } from './beam.js';
import { initMohrModule } from './mohr.js';
import { initTorsionModule } from './torsion.js';
import { initColumnModule } from './column.js';
import { initPressureModule } from './pressure.js';
import { initTrussModule } from './truss.js';
import { initMaterialModule } from './material.js';

initBeamModule();
initMohrModule();
initTorsionModule();
initColumnModule();
initPressureModule();
initTrussModule();
initMaterialModule();
initHelpSystem();

// ═══════════════════════════════════════════════════════════════
// Slider Gradient Fill Enhancement
// ═══════════════════════════════════════════════════════════════
function updateSliderFill(slider) {
    const min = parseFloat(slider.min) || 0;
    const max = parseFloat(slider.max) || 100;
    const val = parseFloat(slider.value) || 0;
    const pct = ((val - min) / (max - min)) * 100;
    slider.style.background = `linear-gradient(90deg, rgba(88,166,255,0.35) 0%, rgba(163,113,247,0.25) ${pct}%, rgba(255,255,255,0.05) ${pct}%)`;
}

document.querySelectorAll('input[type="range"]').forEach(slider => {
    updateSliderFill(slider);
    slider.addEventListener('input', () => updateSliderFill(slider));
});

// Make updateSliderFill available globally for modules that create sliders dynamically
window.updateSliderFill = updateSliderFill;

// Start with beam module active
switchModule('beam');
animate();
