const { cpSync } = require('fs');
const { join } = require('path');

const dest = join(__dirname, '..', 'GLTFPreview');
const libs = join(__dirname, '..', 'node_modules', 'three', 'examples', 'jsm', 'libs');

const files = [
  ['draco', 'draco_decoder.wasm'],
  ['draco', 'draco_wasm_wrapper.js'],
  ['basis', 'basis_transcoder.js'],
  ['basis', 'basis_transcoder.wasm'],
];

for (const [dir, file] of files) {
  cpSync(join(libs, dir, file), join(dest, file));
  console.log(`Copied ${file}`);
}
