import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x2a2a2a);

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.001, 10000);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
renderer.toneMapping = THREE.NeutralToneMapping;
renderer.toneMappingExposure = 0.75;
document.body.appendChild(renderer.domElement);

{
  const pmremGenerator = new THREE.PMREMGenerator(renderer);
  const envScene = new RoomEnvironment();
  scene.environment = pmremGenerator.fromScene(envScene).texture;
  envScene.dispose();
  pmremGenerator.dispose();
}

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.1;

const ktx2Loader = new KTX2Loader();
ktx2Loader.setTranscoderPath('./');
ktx2Loader.detectSupport(renderer);

const dracoLoader = new DRACOLoader();
dracoLoader.setDecoderPath('./');

const loader = new GLTFLoader();
loader.setMeshoptDecoder(MeshoptDecoder);
loader.setKTX2Loader(ktx2Loader);
loader.setDRACOLoader(dracoLoader);

let mixer = null;
const clock = new THREE.Clock();

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

function animate() {
  requestAnimationFrame(animate);
  if (mixer) mixer.update(clock.getDelta());
  controls.update();
  renderer.render(scene, camera);
}
animate();

window.loadModel = function(url) {
  loader.load(url, (gltf) => {
    scene.add(gltf.scene);

    const box = new THREE.Box3().setFromObject(gltf.scene);
    const center = box.getCenter(new THREE.Vector3());
    const size = box.getSize(new THREE.Vector3());
    const maxDim = Math.max(size.x, size.y, size.z);
    const fov = camera.fov * (Math.PI / 180);
    const dist = (maxDim / (2 * Math.tan(fov / 2))) * 1.5;

    camera.near = dist * 0.01;
    camera.far = dist * 10;
    camera.updateProjectionMatrix();

    camera.position.set(
      center.x + dist * 0.5,
      center.y + dist * 0.3,
      center.z + dist
    );
    camera.lookAt(center);
    controls.target.copy(center);
    controls.update();

    if (gltf.animations.length > 0) {
      mixer = new THREE.AnimationMixer(gltf.scene);
      mixer.clipAction(gltf.animations[0]).play();
    }

    document.getElementById('loading')?.remove();

    if (typeof window.customScript === 'function') {
      try { window.customScript({ scene, camera, renderer, controls, gltf, mixer, THREE }); } catch(e) { console.error('Custom script error:', e); }
    }
  }, undefined, (error) => {
    const el = document.getElementById('loading');
    if (el) el.textContent = 'Error: ' + error.message;
  });
};
