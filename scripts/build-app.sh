#!/bin/bash
# Sestaví NAME.app (Release) připravený k instalaci na MacBooku.
# Použití na MacBooku:  ./scripts/build-app.sh
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED="build/DerivedData"
APP="$DERIVED/Build/Products/Release/NAME.app"

echo "==> Build (Release)…"
if ! xcodebuild -project NAME.xcodeproj -scheme NAME -configuration Release \
        -derivedDataPath "$DERIVED" build 2>build/last-build.log; then
    echo "==> Build s automatickým podpisem selhal, zkouším ad-hoc podpis…"
    xcodebuild -project NAME.xcodeproj -scheme NAME -configuration Release \
        -derivedDataPath "$DERIVED" \
        CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual build
fi

test -d "$APP" || { echo "Chyba: $APP nevznikl (viz build/last-build.log)"; exit 1; }

echo "==> Kontrola podpisu…"
if ! codesign --verify --deep --strict "$APP" 2>/dev/null; then
    echo "==> Ad-hoc podpis…"
    codesign --force --deep --sign - "$APP"
fi
codesign --display --verbose=2 "$APP" | head -5 || true

echo "==> ZIP pro přenos…"
mkdir -p build
rm -f build/NAME.zip
ditto -c -k --keepParent "$APP" build/NAME.zip

echo
echo "Hotovo:"
echo "  App:  $APP"
echo "  ZIP:  build/NAME.zip  (přenes na MacBook přes AirDrop/USB, rozbal a přetáhni NAME.app do Applications)"
