#!/bin/bash
# Volitelná notarizace pro distribuci mimo vlastní Mac (vyžaduje Apple Developer ID).
# Před prvním použitím:  xcrun notarytool store-credentials "NAME-notary" …
# Použití:  ./scripts/notarize.sh
set -euo pipefail
cd "$(dirname "$0")/.."

ZIP="build/NAME.zip"
[ -f "$ZIP" ] || ./scripts/build-app.sh

echo "==> Notarizace…"
xcrun notarytool submit "$ZIP" --keychain-profile "NAME-notary" --wait
echo "==> Stapling…"
xcrun stapler staple build/NAME.app 2>/dev/null || true
echo "Hotovo: notarizováno. Pro distribuci použij build/NAME.zip (nebo znovu zabalte notarizovaný .app)."
