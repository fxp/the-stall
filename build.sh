#!/usr/bin/env bash
# Build dist/ from prototype.html.
# Pages project root = the test (Worker xiaopingfeng-router maps
# xiaopingfeng.com/app/the-stall/* → the-stall.pages.dev/*).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

rm -rf dist
mkdir -p dist
cp prototype.html dist/index.html

node -e "
const m = require('fs').readFileSync('dist/index.html','utf8').match(/<script>([\s\S]*?)<\/script>/);
if (!m) { console.error('no <script> block'); process.exit(1); }
new Function(m[1]);
console.log('JS parse OK,', m[1].length, 'chars');
"

echo "✓ build complete:"
find dist -type f | sed 's|^|  |'
