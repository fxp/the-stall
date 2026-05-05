#!/usr/bin/env bash
# Build the deployable dist/ directory from canonical sources.
# Output layout:
#   dist/index.html              ← landing page (from landing.html)
#   dist/app/the-stall/index.html ← distance test (from prototype.html)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

rm -rf dist
mkdir -p dist/app/the-stall

cp landing.html dist/index.html
cp prototype.html dist/app/the-stall/index.html

# Quick syntax check on the inline JS in the test page.
node -e "
const m = require('fs').readFileSync('dist/app/the-stall/index.html','utf8').match(/<script>([\s\S]*?)<\/script>/);
if (!m) { console.error('no <script> block'); process.exit(1); }
new Function(m[1]);
console.log('JS parse OK,', m[1].length, 'chars');
"

echo "✓ build complete:"
find dist -type f | sed 's|^|  |'
